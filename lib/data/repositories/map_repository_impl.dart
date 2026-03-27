import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dart_geohash/dart_geohash.dart';
import 'package:dio/dio.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import 'package:outnest/application/get_it_service_locators/get_it_init.dart';

import 'package:outnest/core/constants/configs/app_config.dart';
import 'package:outnest/core/utils/logging/logging_service.dart';
import 'package:outnest/core/utils/types/geolocation/geolocation.dart';
import 'package:outnest/data/models/event/event_model.dart';
import 'package:outnest/domain/entities/feed/event/event_entity.dart';
import 'package:outnest/domain/repositories/event_repository.dart';
import 'package:outnest/domain/repositories/map_repository.dart';
import 'package:outnest/domain/services/geocoding_service.dart';
import 'package:outnest/domain/services/global_content_cache.dart';
import 'package:outnest/domain/services/in_memory_cache.dart';
import 'package:outnest/domain/services/session_service.dart';

const Map<int, ({double lat, double lon})> _geohashDimensions = {
  3: (lat: 1.40625, lon: 1.40625),
  4: (lat: 0.1757, lon: 0.3515),
  5: (lat: 0.0439, lon: 0.0439),
  6: (lat: 0.0054, lon: 0.0109),
  7: (lat: 0.0013, lon: 0.0013),
};

class MapRepositoryImpl implements MapRepository {
  MapRepositoryImpl({
    required FirebaseFirestore firestore,
    required GlobalContentCache globalCache,
    required LoggingService logger,
    required EventRepository eventRepository,
    required GeocodingService geocodingService,
  }) : _firestore = firestore,
       _globalCache = globalCache,
       _logger = logger,
       _eventRepository = eventRepository,
       _geocodingService = geocodingService;

  final FirebaseFirestore _firestore;
  final GlobalContentCache _globalCache;
  final LoggingService _logger;
  final EventRepository _eventRepository;
  final GeocodingService _geocodingService;
  final GeoHasher _geoHasher = GeoHasher();
  final dio = Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
    ),
  );

  final Set<String> _fetchedRegions = {};
  final Set<String> _fetchLock = {};

  final InMemoryCache<EventEntity> _eventCache = InMemoryCache<EventEntity>(
    cacheSizeLimit: 1000,
    ttl: const Duration(minutes: 30),
  );

  @override
  Future<List<EventEntity>> fetchEventsInBounds({
    required dynamic bounds,
    int precision = 7,
  }) async {
    final expandedBounds = _expandBounds(bounds as CoordinateBounds, 0.5);
    final searchPrecision = _calculateSearchPrecision(expandedBounds);

    final parentGeohashes = _getGeohashesInBounds(
      expandedBounds,
      precision: searchPrecision,
    );

    final newRegions = parentGeohashes.where((h) {
      return !_fetchedRegions.contains(h) && !_fetchLock.contains(h);
    }).toList();

    if (newRegions.isNotEmpty) {
      _fetchLock.addAll(newRegions);

      final futures = <Future<QuerySnapshot>>[];

      for (final parentHash in newRegions) {
        final endHash = '$parentHash~';
        futures.add(
          _firestore
              .collection('events')
              .where('showOnMap', isEqualTo: true)
              .where('status', whereIn: ['upcoming', 'ongoing'])
              .orderBy('geohash')
              .startAt([parentHash])
              .endAt([endHash])
              .limit(50)
              .get(),
        );
      }

      try {
        final snapshots = await Future.wait(futures);

        final eventsToEnrich = <EventEntity>[];

        for (final snap in snapshots) {
          for (final doc in snap.docs) {
            try {
              final eventModel = EventModel.fromFirestore(
                doc.data()! as Map<String, dynamic>,
              );
              eventsToEnrich.add(eventModel.toEntity());
            } catch (e) {
              _logger.error('MapRepo Parse Error: $e');
            }
          }
        }

        final enrichedEvents = await Future.wait(
          eventsToEnrich.map((e) => _eventRepository.enrichEventWithDetails(e)),
        );

        final String? currentUserId =
            getIt<SessionService>().currentUser?.userID;
        final locationInjectedEvents = await Future.wait(
          enrichedEvents.map((e) async {
            return await _eventRepository.injectSensitiveDataIfAuthorized(
              e,
              currentUserId,
            );
          }),
        );

        for (final entity in locationInjectedEvents) {
          _globalCache.cacheEntity(entity);
          _eventCache.set(entity.id, entity);
        }

        _fetchedRegions.addAll(newRegions);
      } catch (e) {
        _logger.error('Fetch hatası: $e');
      } finally {
        _fetchLock.removeAll(newRegions);
      }
    }

    final allCachedEvents = _eventCache.values;
    final visibleEvents = allCachedEvents.where((event) {
      return _isLocationInBounds(event.location, expandedBounds);
    }).toList();

    return visibleEvents;
  }

  // --- YARDIMCI METOTLAR ---

  double _clampLatitude(double lat) {
    return lat.clamp(-90.0, 90.0);
  }

  double _normalizeLongitude(double lng) {
    if (lng >= -180 && lng <= 180) return lng;
    return ((lng + 180) % 360 + 360) % 360 - 180;
  }

  CoordinateBounds _expandBounds(CoordinateBounds bounds, double factor) {
    final southWest = bounds.southwest.coordinates;
    final northEast = bounds.northeast.coordinates;

    final latDiff = northEast.lat.toDouble() - southWest.lat.toDouble();
    final lngDiff = northEast.lng.toDouble() - southWest.lng.toDouble();

    final latBuffer = latDiff * factor;
    final lngBuffer = lngDiff * factor;

    final newSouthLat = _clampLatitude(southWest.lat.toDouble() - latBuffer);
    final newNorthLat = _clampLatitude(northEast.lat.toDouble() + latBuffer);

    final newWestLng = _normalizeLongitude(
      southWest.lng.toDouble() - lngBuffer,
    );
    final newEastLng = _normalizeLongitude(
      northEast.lng.toDouble() + lngBuffer,
    );

    return CoordinateBounds(
      southwest: Point(
        coordinates: Position(newWestLng, newSouthLat),
      ),
      northeast: Point(
        coordinates: Position(newEastLng, newNorthLat),
      ),
      infiniteBounds: false,
    );
  }

  int _calculateSearchPrecision(CoordinateBounds bounds) {
    final latDiff =
        bounds.northeast.coordinates.lat.toDouble() -
        bounds.southwest.coordinates.lat.toDouble();

    if (latDiff > 5.0) return 3;
    if (latDiff > 0.5) return 4;
    if (latDiff > 0.05) return 5;
    return 6;
  }

  List<String> _getGeohashesInBounds(
    CoordinateBounds bounds, {
    required int precision,
  }) {
    final southWest = bounds.southwest.coordinates;
    final northEast = bounds.northeast.coordinates;

    final dimensions = _geohashDimensions[precision] ?? _geohashDimensions[7]!;

    final latStep = dimensions.lat * 0.9;
    final lonStep = dimensions.lon * 0.9;

    final hashes = <String>{};
    const epsilon = 1e-9;

    var currentLat = southWest.lat.toDouble();
    final endLat = northEast.lat.toDouble();
    final endLon = northEast.lng.toDouble();

    while (currentLat < endLat + epsilon) {
      var currentLon = southWest.lng.toDouble();

      while (currentLon < endLon + epsilon) {
        final clampedLat = _clampLatitude(currentLat);
        final normalizedLon = _normalizeLongitude(currentLon);

        final hash = _geoHasher.encode(
          normalizedLon,
          clampedLat,
          precision: precision,
        );
        hashes.add(hash);

        currentLon += lonStep;
      }
      currentLat += latStep;
    }
    return hashes.toList();
  }

  bool _isLocationInBounds(dynamic location, CoordinateBounds bounds) {
    double? lat;
    double? lng;

    try {
      if (location is Geolocation) {
        lat = location.latitude;
        lng = location.longitude;
      } else if (location is Map) {
        lat = (location['latitude'] as num?)?.toDouble();
        lng = (location['longitude'] as num?)?.toDouble();
      }
    } catch (e) {
      _logger.error('Event konum verisi hatalı formatta: $e');
    }

    if (lat == null || lng == null) return false;

    final sw = bounds.southwest.coordinates;
    final ne = bounds.northeast.coordinates;

    return lat >= sw.lat.toDouble() &&
        lat <= ne.lat.toDouble() &&
        lng >= sw.lng.toDouble() &&
        lng <= ne.lng.toDouble();
  }

  @override
  void clearLocalIndex() {
    _fetchedRegions.clear();
    _fetchLock.clear();
    _eventCache.clear();
  }

  @override
  Future<Geolocation?> getPlaceLocation(
    String placeId,
    String sessionToken,
  ) async {
    final accessToken = AppConfig.mapBoxAccessTokenKey;
    if (accessToken.isEmpty) return null;

    try {
      final response = await dio.get(
        'https://api.mapbox.com/search/searchbox/v1/retrieve/$placeId',
        queryParameters: {
          'access_token': accessToken,
          'session_token': sessionToken,
          'language': 'tr',
        },
      );

      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        _logger.info('Place data retrieved: $data');

        final features = data['features'] as List<dynamic>?;
        _logger.info('Place features: $features');

        if (features == null) return null;

        final coordinates = features.isNotEmpty
            ? (features[0]['geometry']['coordinates'] as List<dynamic>?)
            : null;

        _logger.info('Place coordinates: $coordinates');
        if (coordinates == null) return null;

        final latitude = coordinates[1] as double?;
        final longitude = coordinates[0] as double?;
        final location = Geolocation(
          latitude: latitude ?? 0.0,
          longitude: longitude ?? 0.0,
        );

        _logger.info('Place location found: $location');
        return location;
      } else {
        _logger.warn(
          'Mapbox API Error: ${response.statusCode} - ${response.data}',
        );
        return null;
      }
    } catch (e) {
      _logger.warn('Error searching places on Mapbox: $e');
      return null;
    }
  }

  @override
  Future<List<Place>> searchPlaces(
    String query,
    String sessionToken,
    Geolocation? proximity,
  ) async {
    final accessToken = AppConfig.mapBoxAccessTokenKey;
    if (accessToken.isEmpty || query.isEmpty) return [];

    try {
      final response = await dio.get(
        'https://api.mapbox.com/search/searchbox/v1/suggest',
        queryParameters: {
          'q': query,
          'access_token': accessToken,
          'session_token': sessionToken,
          'language': 'tr',
          'limit': '5',
          'country': 'tr',
          'types': 'poi,category,place',
          if (proximity != null)
            'proximity': '${proximity.longitude},${proximity.latitude}',
        },
      );

      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;

        final suggestions = data['suggestions'] as List?;
        if (suggestions == null) return [];

        // Ekstra Mapbox API çağrısı yok.
        // Display address, kullanıcı seçim yaptıktan sonra
        // GeocodingService ile koordinattan hesaplanacak.
        final places = suggestions.map((suggestion) {
          final map = suggestion as Map<String, dynamic>;

          final id = map['mapbox_id'] as String? ?? '';
          final placeName = map['name'] as String? ?? '';
          final adress = map['full_address'] as String? ?? '';

          String fullAdress;
          if (placeName.isEmpty) {
            fullAdress = adress;
          } else if (adress.isEmpty) {
            fullAdress = placeName;
          } else {
            fullAdress = '$placeName, $adress';
          }

          return Place(
            id: id,
            displayAddress:
                '', // Seçim sonrası GeocodingService ile doldurulacak
            adresss: fullAdress,
          );
        }).toList();

        return places;
      } else {
        _logger.warn(
          'Mapbox API Error: ${response.statusCode} - ${response.data}',
        );
        return [];
      }
    } catch (e) {
      _logger.warn('Error searching places on Mapbox: $e');
      return [];
    }
  }

  @override
  Future<Place?> geocodeLocation(
    Geolocation location,
  ) async {
    // 1. Önce lokal GeocodingService ile il/ilçe bilgisini al (anında, API yok)
    final localResult = _geocodingService.getCityDistrictFromGeolocation(
      location,
    );

    String displayAddress;
    if (localResult != null) {
      displayAddress = '${localResult.district}, ${localResult.city}';
      _logger.info(
        'GeocodingService ile displayAddress bulundu: $displayAddress',
      );
    } else {
      _logger.warn(
        'GeocodingService eşleşme bulamadı, Mapbox fallback kullanılıyor',
      );
      displayAddress = '';
    }

    // 2. Full address için Mapbox reverse geocode kullan
    final accessToken = AppConfig.mapBoxAccessTokenKey;
    if (accessToken.isEmpty) {
      if (localResult != null) {
        return Place(
          id: '',
          displayAddress: displayAddress,
          adresss: displayAddress,
        );
      }
      return null;
    }

    try {
      final response = await dio.get(
        'https://api.mapbox.com/search/geocode/v6/reverse',
        queryParameters: {
          'access_token': accessToken,
          'longitude': location.longitude,
          'latitude': location.latitude,
          'language': 'tr',
          'country': 'tr',
          'types':
              'country,region,postcode,district,place,locality,neighborhood,address',
        },
      );

      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;

        final features = data['features'] as List<dynamic>?;
        final properties = features?[0]['properties'] as Map<String, dynamic>?;
        if (properties == null || properties.isEmpty) {
          if (localResult != null) {
            return Place(
              id: '',
              displayAddress: displayAddress,
              adresss: displayAddress,
            );
          }
          return null;
        }

        final fullAddress = properties['full_address'] as String? ?? '';

        // GeocodingService bulamadıysa Mapbox'a fallback yap
        if (localResult == null) {
          final city =
              properties['context']?['region']?['name'] as String? ?? '';
          final district =
              properties['context']?['place']?['name'] as String? ?? '';
          displayAddress = city.isNotEmpty ? '$district, $city' : district;
        }

        _logger.info('Geocoded place: $displayAddress, $fullAddress');
        return Place(
          id: '',
          displayAddress: displayAddress,
          adresss: fullAddress.isNotEmpty ? fullAddress : displayAddress,
        );
      } else {
        _logger.warn('Mapbox API Error: ${response.statusCode}');
        if (localResult != null) {
          return Place(
            id: '',
            displayAddress: displayAddress,
            adresss: displayAddress,
          );
        }
        return null;
      }
    } catch (e) {
      _logger.warn('Error in geocodeLocation: $e');
      if (localResult != null) {
        return Place(
          id: '',
          displayAddress: displayAddress,
          adresss: displayAddress,
        );
      }
      return null;
    }
  }
}
