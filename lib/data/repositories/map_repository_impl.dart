import 'package:bulusalim/core/utils/logging/logging_service.dart';
import 'package:bulusalim/core/utils/types/types.dart';
import 'package:bulusalim/data/models/event/event_model.dart';
import 'package:bulusalim/domain/entities/feed/event/event_entity.dart';
import 'package:bulusalim/domain/repositories/map_repository.dart';
import 'package:bulusalim/domain/services/global_content_cache.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dart_geohash/dart_geohash.dart'; // Geohash paketi
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart'; // Mapbox paketi

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

  // Key: Geohash, Value: Event ID Listesi
  final Map<String, List<Identifier>> _geohashIndex = {};

  // Fetch edilmiş kutular
  final Set<String> _fetchedGeohashes = {};

  static const int _firestoreQueryLimit = 10;

  @override
  Future<List<EventEntity>> fetchEventsInBounds({
    required dynamic bounds, // Mapbox CoordinateBounds gelecek
    int precision = 7,
  }) async {
    // Gelen bounds null mı kontrol et
    if (bounds == null) {
      _logger.error('MapRepository Error: bounds is NULL');
      return [];
    }

    // Gelen bounds CoordinateBounds değil mi kontrol et
    if (bounds is! CoordinateBounds) {
      _logger.error(
        'MapRepository Error: Expected CoordinateBounds but received ${bounds.runtimeType}. Value: $bounds',
      );
      return [];
    }
    // 1. Tip Güvenliği: Gelen bounds'u Mapbox tipine cast ediyoruz
    if (bounds is! CoordinateBounds) {
      _logger.error('Invalid bounds type provided to MapRepository');
      return [];
    }

    // 2. Görünür alandaki kutuları hesapla
    final visibleGeohashes = _getGeohashesInBounds(
      bounds,
      precision: precision,
    );
    _logger.info(
      'MapRepo: Calculated ${visibleGeohashes.length} tiles. List: $visibleGeohashes',
    );

    // 3. Eksikleri belirle
    final missingGeohashes = visibleGeohashes
        .where((hash) => !_fetchedGeohashes.contains(hash))
        .toList();

    // 4. Eksikleri Firestore'dan çek
    if (missingGeohashes.isNotEmpty) {
      await _fetchMissingGeohashes(missingGeohashes);
    }

    // 5. Görünür alandaki tüm ID'leri topla
    final visibleEventIds = <Identifier>{};
    for (final geoHash in visibleGeohashes) {
      final idsInTile = _geohashIndex[geoHash];
      if (idsInTile != null) {
        visibleEventIds.addAll(idsInTile);
      }
    }

    // 6. Global Cache'ten verileri çek ve EventEntity olarak filtrele
    final entities = _globalCache.getEntities(visibleEventIds.toList());
    _logger.info('MapRepo: Fetched ${entities.length} events from Firestore.');
    return entities.whereType<EventEntity>().toList();
  }

  Future<void> _fetchMissingGeohashes(List<String> missingGeohashes) async {
    final chunks = <List<String>>[];
    // Listeyi 10'arlı parçalara böl (Firestore IN limiti)
    for (var i = 0; i < missingGeohashes.length; i += _firestoreQueryLimit) {
      chunks.add(
        missingGeohashes.sublist(
          i,
          (i + _firestoreQueryLimit > missingGeohashes.length)
              ? missingGeohashes.length
              : i + _firestoreQueryLimit,
        ),
      );
    }

    // Paralel istek at
    final futures = chunks.map((chunk) {
      return _firestore
          .collection('feed')
          .where('feedType', isEqualTo: 'event')
          .where('geohash', whereIn: chunk)
          .get();
    });

    final snapshots = await Future.wait(futures);

    for (final snapshot in snapshots) {
      for (final doc in snapshot.docs) {
        try {
          final eventModel = EventModel.fromFirestore(doc.data());
          final eventEntity = eventModel.toEntity();

          // A. Global Cache'e yaz
          _globalCache.cacheEntity(eventEntity);

          // B. Local Index'e işle
          final eventGeohash = doc.data()['geohash'] as String;

          if (!_geohashIndex.containsKey(eventGeohash)) {
            _geohashIndex[eventGeohash] = [];
          }
          // Duplicate önlemek için check
          if (!_geohashIndex[eventGeohash]!.contains(eventEntity.id)) {
            _geohashIndex[eventGeohash]!.add(eventEntity.id);
          }
        } catch (e) {
          _logger.error('MapRepo Parse Error: $e');
        }
      }
    }

    // İşlenenleri işaretle
    _fetchedGeohashes.addAll(missingGeohashes);
  }

  @override
  List<String> _getGeohashesInBounds(
    CoordinateBounds bounds, {
    required int precision,
  }) {
    final southWest = bounds.southwest.coordinates;
    final northEast = bounds.northeast.coordinates;

    // Harita çok uzaksa veya sınırlar geçersizse boş dön
    if (southWest.lat.toDouble() <= -90 && northEast.lat.toDouble() >= 90)
      return [];

    // --- KUTU BOYUTUNU (STEP SIZE) MATEMATİKSEL HESAPLA ---
    // Geohash standardına göre hassasiyet arttıkça alan ikiye bölünür.
    // Bu algoritma, verilen hassasiyette bir kutunun kaç derece (enlem/boylam) olduğunu bulur.

    double latMin = -90, latMax = 90;
    double lonMin = -180, lonMax = 180;
    var isLon = true;

    // Her karakter 5 bit veriye eşittir.
    for (var i = 0; i < precision * 5; i++) {
      if (isLon) {
        final mid = (lonMin + lonMax) / 2;
        // Sadece aralığı daraltarak boyutu ölçüyoruz
        lonMax = mid;
      } else {
        final mid = (latMin + latMax) / 2;
        latMax = mid;
      }
      isLon = !isLon;
    }

    // Artık o hassasiyetteki bir kutunun yüksekliğini ve genişliğini biliyoruz.
    final latStep = latMax - latMin;
    final lonStep = lonMax - lonMin;
    // -----------------------------------------------------

    final hashes = <String>{};

    var currentLat = southWest.lat.toDouble();
    final endLat = northEast.lat.toDouble();
    final endLon = northEast.lng.toDouble();

    // Floating point hatalarını yutmak için küçük tolerans
    const epsilon = 0.000001;

    // Grid taraması
    // Not: Lat/Lon sınırları aşmasın diye while koşulunu güvenli tutuyoruz
    while (currentLat < endLat + epsilon) {
      var currentLon = southWest.lng.toDouble();
      while (currentLon < endLon + epsilon) {
        final hash = _geoHasher.encode(
          currentLon,
          currentLat,
          precision: precision,
        );
        hashes.add(hash);

        currentLon += lonStep;
      }
      currentLat += latStep;
    }

    return hashes.toList();
  }

  @override
  void clearLocalIndex() {
    _fetchedGeohashes.clear();
    _geohashIndex.clear();
  }
}
