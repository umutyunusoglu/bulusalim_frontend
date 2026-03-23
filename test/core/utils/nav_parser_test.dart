import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:outnest/core/utils/nav_parser.dart';
import '../../test_helpers/test_helpers.dart';

void main() {
  group('parseAndSortNavConfig', () {
    final allPages = <String, Widget>{
      'home': const SizedBox.shrink(),
      'search': const Placeholder(),
      'map': const Center(),
      'chat': const Text('chat'),
    };

    final allIcons = <String, IconData>{
      'home': Icons.home,
      'search': Icons.search,
      'map': Icons.map,
      'chat': Icons.chat,
    };

    test('throws when jsonString is empty', () {
      expect(
        () => parseAndSortNavConfig(
          jsonString: '',
          allPages: allPages,
          allIcons: allIcons,
        ),
        throwsA(isA<Exception>()),
      );
    });

    test('sorts entries and keeps only known page/icon keys', () {
      final result = parseAndSortNavConfig(
        jsonString: TestHelpers.encodeJson({
          'chat': 3,
          'home': 1,
          'unknown': 2,
          'map': '2',
        }),
        allPages: allPages,
        allIcons: allIcons,
      );

      expect(result.icons, [Icons.home, Icons.map, Icons.chat]);
      expect(result.pages.length, 3);
    });

    test('puts non-numeric sort values at the end', () {
      final result = parseAndSortNavConfig(
        jsonString: TestHelpers.encodeJson({
          'home': 1,
          'chat': 'zzz',
          'search': 2,
        }),
        allPages: allPages,
        allIcons: allIcons,
      );

      expect(result.icons, [Icons.home, Icons.search, Icons.chat]);
    });

    test('throws when fewer than two valid nav items remain', () {
      expect(
        () => parseAndSortNavConfig(
          jsonString: TestHelpers.encodeJson({
            'unknown': 1,
            'home': 2,
          }),
          allPages: allPages,
          allIcons: allIcons,
        ),
        throwsA(isA<Exception>()),
      );
    });
  });
}
