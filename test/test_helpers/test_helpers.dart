import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

/// Shared helpers for unit tests.
///
/// How to use this file:
/// 1) Import it in your test file:
///    import '../../test_helpers/test_helpers.dart';
/// 2) Use [setAssetString] when a class reads data via rootBundle.loadString.
/// 3) Call [clearAssetMocks] in tearDown to avoid test leakage.
/// 4) Use [encodeJson] for readable JSON fixture setup.
/// 5) Use [dateYearsAgo] for age/date boundary tests.
///
/// Tip: Because this folder is under /test (not /lib), prefer relative imports
/// from other test files.
class TestHelpers {
  TestHelpers._();

  /// Converts any Dart object to a JSON string fixture.
  static String encodeJson(Object value) => jsonEncode(value);

  /// Installs a mock flutter asset response for [assetPath].
  ///
  /// Example:
  /// await TestHelpers.setAssetString(
  ///   assetPath: 'assets/data/universities.json',
  ///   content: '[{"name":"Bogazici University","domains":["boun.edu.tr"]}]',
  /// );
  static Future<void> setAssetString({
    required String assetPath,
    required String content,
  }) async {
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;

    messenger.setMockMessageHandler('flutter/assets', (
      ByteData? message,
    ) async {
      if (message == null) return null;
      final key = utf8.decode(message.buffer.asUint8List());
      if (key != assetPath) return null;

      final bytes = Uint8List.fromList(utf8.encode(content));
      return ByteData.sublistView(bytes);
    });
  }

  /// Clears any asset mocks installed through [setAssetString].
  static Future<void> clearAssetMocks() async {
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    messenger.setMockMessageHandler('flutter/assets', null);
  }

  /// Returns a date set [years] years before today.
  /// Useful for age-gate validators.
  static DateTime dateYearsAgo(int years) {
    final now = DateTime.now();
    return DateTime(now.year - years, now.month, now.day);
  }
}
