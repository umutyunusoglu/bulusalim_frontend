import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dart_geohash/dart_geohash.dart';
import 'package:dio/dio.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import 'package:outnest/application/providers/get_it_init.dart';
// min, max, clamp için

import 'package:outnest/core/constants/configs/app_config.dart';
import 'package:outnest/core/utils/logging/logging_service.dart';
import 'package:outnest/core/utils/types/geolocation/geolocation.dart';
import 'package:outnest/data/models/event/event_model.dart';
import 'package:outnest/domain/entities/feed/event/event_entity.dart';
import 'package:outnest/domain/repositories/event_repository.dart';
import 'package:outnest/domain/repositories/map_repository.dart';
import 'package:outnest/domain/services/global_content_cache.dart';
import 'package:outnest/domain/services/in_memory_cache.dart';
import 'package:outnest/domain/services/session_service.dart';

// FIX: Magic Numbers Lookup Table'a taşındı.
// Her precision seviyesi için yaklaşık derece (lat, lon) boyutları.
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
  }) : _firestore = firestore,
       _globalCache = globalCache,
       _logger = logger,
       _eventRepository = eventRepository;

  final FirebaseFirestore _firestore;
  final GlobalContentCache _globalCache;
  final LoggingService _logger;
  final EventRepository _eventRepository;
  final GeoHasher _geoHasher = GeoHasher();
  final dio = Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
    ),
  );

  // Daha önce başarıyla çekilmiş region'lar
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
    // 1. Koordinat hesaplamaları
    final expandedBounds = _expandBounds(bounds as CoordinateBounds, 0.5);
    final searchPrecision = _calculateSearchPrecision(expandedBounds);

    // 2. Bölgeleri Hesapla
    final parentGeohashes = _getGeohashesInBounds(
      expandedBounds,
      precision: searchPrecision,
    );

    // 3. Henüz çekilmemiş VE şu an başkası tarafından çekilmeyen bölgeleri bul
    final newRegions = parentGeohashes.where((h) {
      return !_fetchedRegions.contains(h) && !_fetchLock.contains(h);
    }).toList();

    if (newRegions.isNotEmpty) {
      // İşleme girenleri kilitle
      _fetchLock.addAll(newRegions);

      final futures = <Future<QuerySnapshot>>[];

      for (final parentHash in newRegions) {
        final endHash = '$parentHash~';
        futures.add(
          _firestore
              .collection('events')
              .where('showOnMap', isEqualTo: true)
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

        // Zenginleştirilmiş verileri cache'e yazıyoruz
        for (final entity in locationInjectedEvents) {
          // Global Cache (Detay sayfası için hazır olsun)
          _globalCache.cacheEntity(entity);
          // Map Cache (Harita gösterimi için)
          _eventCache.set(entity.id, entity);
        }

        // Başarılı olan bölgeleri fetched listesine ekle
        _fetchedRegions.addAll(newRegions);
      } catch (e) {
        _logger.error('Fetch hatası: $e');
      } finally {
        // İşlem bitince kilidi aç
        _fetchLock.removeAll(newRegions);
      }
    }

    // 4. Cache'ten şu anki ekrana uyanları filtrele ve döndür
    final allCachedEvents = _eventCache.values;
    final visibleEvents = allCachedEvents.where((event) {
      return _isLocationInBounds(event.location, expandedBounds);
    }).toList();

    return visibleEvents;
  }

  // --- YARDIMCI METOTLAR ---

  /// Enlemi -90 ile +90 arasında tutar (Kutuplar)
  double _clampLatitude(double lat) {
    return lat.clamp(-90.0, 90.0);
  }

  /// Boylamı -180 ile +180 arasına sığdırır (Dünya turu/Wrapping)
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

    // FIX: Güvenli matematik fonksiyonları kullanıldı
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

    // FIX: Lookup Table kullanımı
    final dimensions = _geohashDimensions[precision] ?? _geohashDimensions[7]!;

    // FIX: Overlap garantisi için step aralığını %10 küçültüyoruz
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
        // FIX: Koordinatları normalize et
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

    // Basit box check (Antimeridian durumu için ekstra logic eklenebilir ama şu an yeterli)
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
    // Access token veya query boş ise direkt boş dön
    if (accessToken.isEmpty) return null;

    try {
      // 1. DÜZELTME: Uri yapısı ve query parametresi
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
        // 2. DÜZELTME: Güvenli liste dönüşümü

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
      // 5. DÜZELTME: Hatayı logluyoruz
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
    // Access token veya query boş ise direkt boş dön
    if (accessToken.isEmpty || query.isEmpty) return [];

    try {
      // 1. DÜZELTME: Uri yapısı ve query parametresi
      final response = await dio.get(
        'https://api.mapbox.com/search/searchbox/v1/suggest',
        queryParameters: {
          'q': query, // "search_text" yerine gerçek query
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

        // 2. DÜZELTME: Güvenli liste dönüşümü
        final suggestions = data['suggestions'] as List?;

        if (suggestions == null) return [];

        final places = suggestions.map((suggestion) async {
          // suggestion dynamic olabilir, Map'e cast ediyoruz
          final map = suggestion as Map<String, dynamic>;
          _logger.info('Processing suggestion: $map');

          final id = map['mapbox_id'] as String? ?? '';

          // TODO: UI'da name ve full adress ayrı gösterilebilir.
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

          //TODO: Burada context içinden şehir ve ilçe bilgilerini almak daha doğru olabilir
          final context = map['context'] as Map<String, dynamic>? ?? {};
          String city, district;
          if (context.isEmpty) {
            _logger.warn('Suggestion context is empty for place: $placeName');
            city = map['region'] as String? ?? '';
            district = map['place'] as String? ?? '';
          } else {
            city = context['region']?['name'] as String? ?? '';
            district = context['place']?['name'] as String? ?? '';
          }

          if (city.isEmpty) {
            final cityResponse = await dio.get(
              'https://api.mapbox.com/search/searchbox/v1/suggest',
              queryParameters: {
                'q': district,
                'access_token': accessToken,
                'session_token': sessionToken,
                'language': 'tr',
                'limit': '5',
                'country': 'tr',
                'types': 'place',
                if (proximity != null)
                  'proximity': '${proximity.longitude},${proximity.latitude}',
              },
            );

            final cityData = cityResponse.data as Map<String, dynamic>;
            final citySuggestions = cityData['suggestions'] as List?;
            if (citySuggestions != null && citySuggestions.isNotEmpty) {
              // İlk öneriyi al
              final firstSuggestion =
                  citySuggestions[0] as Map<String, dynamic>;

              // Önerinin içindeki context'e git
              final contextObj =
                  firstSuggestion['context'] as Map<String, dynamic>? ?? {};

              // Şehri (region) oradan çek
              city = contextObj['region']?['name'] as String? ?? '';

              // EĞER context boşsa, bazen suggestion'ın kendisi de bir 'region' tipinde olabilir
              if (city.isEmpty) {
                city = firstSuggestion['name'] as String? ?? '';
              }
            }
          }

          var displayAdress = city.isNotEmpty ? '$district, $city' : district;

          if (displayAdress.isEmpty) {
            displayAdress = placeName;
          }

          _logger.info('Place found: $displayAdress and address: $placeName');
          return Place(
            id: id,
            displayAddress: displayAdress,
            adresss: fullAdress,
          );
        }).toList();

        // 4. DÜZELTME: Listeyi return ediyoruz
        return Future.wait(places);
      } else {
        _logger.warn(
          'Mapbox API Error: ${response.statusCode} - ${response.data}',
        );
        return [];
      }
    } catch (e) {
      // 5. DÜZELTME: Hatayı logluyoruz
      _logger.warn('Error searching places on Mapbox: $e');
      return [];
    }
  }

  @override
  Future<Place?> geocodeLocation(
    Geolocation location,
  ) async {
    final accessToken = AppConfig.mapBoxAccessTokenKey;
    if (accessToken.isEmpty) return null;

    try {
      final response = await dio.get(
        'https://api.mapbox.com/search/geocode/v6/reverse',
        queryParameters: {
          'access_token': accessToken,
          'longitude': location.longitude,
          'latitude': location.latitude,
          'language': 'tr',
          'country': 'tr',
          // 'street' parametresi v6'da geçersizdir, kaldırıldı.
          'types':
              'country,region,postcode,district,place,locality,neighborhood,address',
        },
      );

      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;

        final features = data['features'] as List<dynamic>?;
        final properties = features?[0]['properties'] as Map<String, dynamic>?;
        // Features listesi boşsa null dön
        if (properties == null || properties.isEmpty) return null;

        final city = properties['context']?['region']?['name'] as String? ?? '';

        final district =
            properties['context']?['place']?['name'] as String? ?? '';

        final displayAddress = city.isNotEmpty ? '$district, $city' : district;

        final fullAddress = properties['full_address'] as String? ?? '';

        _logger.info('Geocoded place: $displayAddress, $fullAddress');
        return Place(
          id: '', // İsterseniz properties['mapbox_id'] kullanabilirsiniz
          displayAddress: displayAddress,
          adresss: fullAddress,
        );
      } else {
        _logger.warn('Mapbox API Error: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      _logger.warn('Error searching places on Mapbox: $e');
      return null;
    }
  }
}
