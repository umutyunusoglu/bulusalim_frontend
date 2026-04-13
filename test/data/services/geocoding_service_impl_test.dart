import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:outnest/core/utils/types/geolocation/geolocation.dart';
import 'package:outnest/data/services/geocoding_service_impl.dart';

// ---------------------------------------------------------------------------
// Asset stub – serves the real turkey_map.json from the assets folder.
//
// rootBundle encodes the asset key with StringCodec (4-byte big-endian
// length prefix + UTF-8). We decode with the same codec to match the key,
// then return the raw file bytes.
// ---------------------------------------------------------------------------

void _registerTurkeyMapAsset() {
  final bytes = File('assets/data/turkey_map.json').readAsBytesSync();
  final byteData = ByteData.sublistView(bytes);

  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMessageHandler('flutter/assets', (ByteData? message) async {
        if (message == null) return null;
        final String key;
        try {
          key = const StringCodec().decodeMessage(message) as String;
        } catch (_) {
          return null;
        }
        if (key != 'assets/data/turkey_map.json') return null;
        return byteData;
      });
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late GeocodingServiceImpl service;

  setUpAll(() async {
    _registerTurkeyMapAsset();
    service = GeocodingServiceImpl();
    await service.init();
  });

  // ── Kadıköy / Istanbul ───────────────────────────────────────────────────
  //
  // Real bbox:  lon 29.00600–29.09810, lat 40.96490–41.02900
  // Centroid:   lon 29.05205,          lat 40.99695  (verified inside)

  group('Kadıköy – Istanbul', () {
    test('centroid of Kadıköy is matched correctly', () {
      final result = service.getCityDistrictFromGeolocation(
        const Geolocation(latitude: 40.99695, longitude: 29.05205),
      );
      expect(result, isNotNull);
      expect(result!.city, 'Istanbul');
      expect(result.district, 'Kadıköy');
    });

    test(
      'point clearly outside Kadıköy returns a different or null result',
      () {
        // Null island — nowhere near Turkey
        final result = service.getCityDistrictFromGeolocation(
          const Geolocation(latitude: 0, longitude: 0),
        );
        expect(result?.district, isNot('Kadıköy'));
      },
    );

    test('point north of Istanbul is not matched to Kadıköy', () {
      final result = service.getCityDistrictFromGeolocation(
        const Geolocation(latitude: 50, longitude: 29.05205),
      );
      expect(result?.district, isNot('Kadıköy'));
    });
  });

  // ── Keskin / Kırıkkale ───────────────────────────────────────────────────
  //
  // Real bbox:  lon 33.43580–34.00290, lat 39.38110–39.80680
  // Centroid:   lon 33.71935,          lat 39.59395  (verified inside)

  group('Keskin – Kırıkkale', () {
    test('centroid of Keskin is matched correctly', () {
      final result = service.getCityDistrictFromGeolocation(
        const Geolocation(latitude: 39.59395, longitude: 33.71935),
      );
      expect(result, isNotNull);
      expect(result!.city, 'Kırıkkale'); // stored name in the dataset
      expect(result.district, 'Keskin');
    });

    test('point west of Keskin bbox is not matched to Keskin', () {
      // lon 30.0 is well outside the 33.4–34.0 range
      final result = service.getCityDistrictFromGeolocation(
        const Geolocation(latitude: 39.59395, longitude: 30),
      );
      expect(result?.district, isNot('Keskin'));
    });

    test('point east of Keskin bbox is not matched to Keskin', () {
      final result = service.getCityDistrictFromGeolocation(
        const Geolocation(latitude: 39.59395, longitude: 35),
      );
      expect(result?.district, isNot('Keskin'));
    });
  });

  // ── Bornova / İzmir ──────────────────────────────────────────────────────
  //
  // Real bbox:  lon 27.15270–27.37760, lat 38.38040–38.58830
  // Centroid:   lon 27.26515,          lat 38.48435  (verified inside)

  group('Bornova – Izmir', () {
    test('centroid of Bornova is matched correctly', () {
      final result = service.getCityDistrictFromGeolocation(
        const Geolocation(latitude: 38.48435, longitude: 27.26515),
      );
      expect(result, isNotNull);
      expect(result!.city, 'Izmir');
      expect(result.district, 'Bornova');
    });

    test('point south of Bornova bbox is not matched to Bornova', () {
      // lat 37.0 is south of the 38.38–38.59 range
      final result = service.getCityDistrictFromGeolocation(
        const Geolocation(latitude: 37, longitude: 27.26515),
      );
      expect(result?.district, isNot('Bornova'));
    });

    test('point east of Bornova bbox is not matched to Bornova', () {
      final result = service.getCityDistrictFromGeolocation(
        const Geolocation(latitude: 38.48435, longitude: 28.5),
      );
      expect(result?.district, isNot('Bornova'));
    });
  });

  // ── Cross-district sanity checks ─────────────────────────────────────────

  group('cross-district sanity', () {
    test('Kadıköy centroid is not matched to Bornova', () {
      final result = service.getCityDistrictFromGeolocation(
        const Geolocation(latitude: 40.99695, longitude: 29.05205),
      );
      expect(result?.district, isNot('Bornova'));
    });

    test('Bornova centroid is not matched to Keskin', () {
      final result = service.getCityDistrictFromGeolocation(
        const Geolocation(latitude: 38.48435, longitude: 27.26515),
      );
      expect(result?.district, isNot('Keskin'));
    });

    test('point over the Black Sea returns null', () {
      // lon=32, lat=43 — well north of Turkey's coast
      final result = service.getCityDistrictFromGeolocation(
        const Geolocation(latitude: 43, longitude: 32),
      );
      expect(result, isNull);
    });

    test('point over the Mediterranean returns null', () {
      final result = service.getCityDistrictFromGeolocation(
        const Geolocation(latitude: 33, longitude: 30),
      );
      expect(result, isNull);
    });
  });
}
