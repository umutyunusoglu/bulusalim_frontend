import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:outnest/core/utils/types/geolocation/geolocation.dart';
import 'package:outnest/domain/services/geocoding_service.dart';

class GeocodingServiceImpl implements GeocodingService {
  List<dynamic> _features = [];

  Future<void> init() async {
    final raw = await rootBundle.loadString('assets/turkey_map.json');
    final geojson = jsonDecode(raw) as Map<String, dynamic>;
    _features = geojson['features'] as List<dynamic>;
  }

  @override
  ({String city, String district})? getCityDistrictFromGeolocation(
    Geolocation geolocation,
  ) {
    final point = [geolocation.longitude, geolocation.latitude];

    for (final feature in _features.cast<Map<String, dynamic>>()) {
      if (_pointInPolygon(point, feature)) {
        final props = feature['properties'] as Map<String, dynamic>;
        return (
          city: props['NAME_1'] as String,
          district: props['NAME_2'] as String,
        );
      }
    }

    return null;
  }

  bool _pointInPolygon(List<double> point, Map<String, dynamic> feature) {
    final geom = feature['geometry'] as Map<String, dynamic>;
    final type = geom['type'] as String;
    final coords = geom['coordinates'] as List<dynamic>;

    if (type == 'Polygon') return _checkPolygon(point, coords);
    if (type == 'MultiPolygon') {
      return coords.any((p) => _checkPolygon(point, p as List));
    }
    return false;
  }

  bool _checkPolygon(List<double> point, List<dynamic> rings) {
    if (!_pointInRing(point, rings[0] as List)) return false;
    for (int i = 1; i < rings.length; i++) {
      if (_pointInRing(point, rings[i] as List)) return false;
    }
    return true;
  }

  bool _pointInRing(List<double> point, List<dynamic> ring) {
    final px = point[0], py = point[1];
    bool inside = false;

    for (int i = 0, j = ring.length - 1; i < ring.length; j = i++) {
      final xi = (ring[i][0] as num).toDouble();
      final yi = (ring[i][1] as num).toDouble();
      final xj = (ring[j][0] as num).toDouble();
      final yj = (ring[j][1] as num).toDouble();

      if ((yi > py) != (yj > py) &&
          px < ((xj - xi) * (py - yi) / (yj - yi) + xi)) {
        inside = !inside;
      }
    }

    return inside;
  }
}
