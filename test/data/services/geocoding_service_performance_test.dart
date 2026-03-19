import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:outnest/core/utils/types/geolocation/geolocation.dart';
import 'package:outnest/data/services/geocoding_service_impl.dart';

// ---------------------------------------------------------------------------
// Performance tests for GeocodingServiceImpl.getCityDistrictFromGeolocation
//
// Best case    : Adana / Aladağ      — index 0,   match found immediately
// Average case : Istanbul / Ümraniye — index 464, ~half the list scanned
// Worst case   : Outside Turkey      — all 929 features scanned, no match
// ---------------------------------------------------------------------------

const int _iterations = 1000;
const double _thresholdUs = 1000; // 200ms in microseconds

void _registerAssetBytes(ByteData byteData) {
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

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late GeocodingServiceImpl service;

  setUpAll(() async {
    final bytes = await File('assets/data/turkey_map.json').readAsBytes();
    _registerAssetBytes(ByteData.sublistView(bytes));
    service = GeocodingServiceImpl();
    await service.init();
  });

  double _measure(Geolocation geo) {
    final sw = Stopwatch()..start();
    for (var i = 0; i < _iterations; i++) {
      service.getCityDistrictFromGeolocation(geo);
    }
    sw.stop();
    return sw.elapsedMicroseconds / _iterations;
  }

  String _fmt(double us) =>
      '${us.toStringAsFixed(1)}µs  (${(us / 1000).toStringAsFixed(3)}ms)';

  test('best case – Adana/Aladağ (index 0)', () {
    const geo = Geolocation(latitude: 37.62455, longitude: 35.36700);
    final avg = _measure(geo);
    // ignore: avoid_print
    print('Best case avg: ${_fmt(avg)} over $_iterations runs');
    expect(avg, lessThan(_thresholdUs));
  });

  test('average case – Istanbul/Ümraniye (index 464)', () {
    const geo = Geolocation(latitude: 41.03900, longitude: 29.12910);
    final avg = _measure(geo);
    // ignore: avoid_print
    print('Average case avg: ${_fmt(avg)} over $_iterations runs');
    expect(avg, lessThan(_thresholdUs));
  });

  test('worst case – outside Turkey (all 929 features scanned, no match)', () {
    const geo = Geolocation(latitude: 0.0, longitude: 0.0);
    final avg = _measure(geo);
    // ignore: avoid_print
    print('Worst case avg: ${_fmt(avg)} over $_iterations runs');
    expect(avg, lessThan(_thresholdUs));
  });
}
