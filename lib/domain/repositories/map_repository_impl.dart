import 'dart:async';
import 'dart:math'; // min, max, clamp için

import 'package:bulusalim/core/utils/logging/logging_service.dart';
import 'package:bulusalim/core/utils/types/geolocation/geolocation.dart';
import 'package:bulusalim/data/models/event/event_model.dart';
import 'package:bulusalim/domain/entities/feed/event/event_entity.dart';
import 'package:bulusalim/domain/repositories/map_repository.dart';
import 'package:bulusalim/domain/services/global_content_cache.dart';
import 'package:bulusalim/domain/services/in_memory_cache.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dart_geohash/dart_geohash.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';

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
  }) : _firestore = firestore,
       _globalCache = globalCache,
       _logger = logger;

  final FirebaseFirestore _firestore;
  final GlobalContentCache _globalCache;
  final LoggingService _logger;
  final GeoHasher _geoHasher = GeoHasher();

  // Daha önce başarıyla çekilmiş region'lar
  final Set<String> _fetchedRegions = {};

  // FIX: Concurrency Bug - Aynı anda aynı bölgeye istek atılmasını önleyen kilit
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
    // 1. Koordinat hesaplamaları (Refactor edilmiş güvenli hali)
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
      // _logger.info('🔍 MapRepo: Fetching ${newRegions.length} new regions...');

      // FIX: İşleme girenleri kilitle
      _fetchLock.addAll(newRegions);

      List<Future<QuerySnapshot>> futures = [];

      // FIX: Batching - Limitli sorgular
      for (String parentHash in newRegions) {
        final endHash = '$parentHash~';
        futures.add(
          _firestore
              .collection('feed')
              .where('feedType', isEqualTo: 'event')
              .orderBy('geohash')
              .startAt([parentHash])
              .endAt([endHash])
              .limit(50) // FIX: Firestore Limit (Cost Control)
              .get(),
        );
      }

      try {
        final snapshots = await Future.wait(futures);

        for (final snap in snapshots) {
          for (final doc in snap.docs) {
            try {
              final eventModel = EventModel.fromFirestore(
                doc.data() as Map<String, dynamic>,
              );
              final entity = eventModel.toEntity();

              // Global Cache (Detay sayfası için)
              _globalCache.cacheEntity(entity);
              // Map Cache (Harita gösterimi için)
              _eventCache.set(entity.id, entity);
            } catch (e) {
              _logger.error('MapRepo Parse Error: $e');
            }
          }
        }

        // Başarılı olanları fetched listesine ekle
        _fetchedRegions.addAll(newRegions);
      } catch (e) {
        _logger.error("Fetch hatası: $e");
        // Hata durumunda yeniden denenebilmesi için fetched'a eklemiyoruz
      } finally {
        // FIX: İşlem bitince (başarılı/başarısız) kilidi mutlaka aç
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
    } catch (_) {}

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
}
