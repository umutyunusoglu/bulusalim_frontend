import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:outnest/application/service_locators/get_it_init.dart';
import 'package:outnest/core/utils/logging/logging_service.dart';
import 'package:outnest/data/datasources/university_datasource_impl.dart';
import 'package:outnest/domain/services/remote_config_service.dart';
import '../../test_helpers/test_helpers.dart';

class _MockRemoteConfigService extends Mock implements RemoteConfigService {}

class _MockLoggingService extends Mock implements LoggingService {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late _MockRemoteConfigService remoteConfigService;
  late _MockLoggingService loggingService;
  late UniversityDataSourceImpl dataSource;

  const assetPath = 'assets/data/universities.json';

  setUp(() async {
    await getIt.reset();

    remoteConfigService = _MockRemoteConfigService();
    loggingService = _MockLoggingService();

    when(() => loggingService.debug(any())).thenReturn(null);
    when(() => loggingService.error(any())).thenReturn(null);
    when(() => loggingService.info(any())).thenReturn(null);
    when(() => loggingService.warn(any())).thenReturn(null);
    when(() => loggingService.trace(any())).thenReturn(null);
    when(() => loggingService.fatal(any())).thenReturn(null);

    getIt.registerSingleton<RemoteConfigService>(remoteConfigService);
    dataSource = UniversityDataSourceImpl(logger: loggingService);
    await TestHelpers.clearAssetMocks();
  });

  tearDown(() async {
    await TestHelpers.clearAssetMocks();
    await getIt.reset();
  });

  group('UniversityDataSourceImpl', () {
    test('loads universities from Remote Config and caches result', () async {
      final jsonData = TestHelpers.encodeJson([
        {
          'name': 'Bogazici University',
          'domains': ['boun.edu.tr'],
        },
        {
          'name': 'Middle East Technical University',
          'domains': ['metu.edu.tr'],
        },
      ]);

      when(
        () => remoteConfigService.getValue<String>('universities'),
      ).thenAnswer((_) async => jsonData);

      final byMail = await dataSource.getUniversityOfMail(
        'student@metu.edu.tr',
        null,
      );
      final byName = await dataSource.getAllUniversitiesInCountry(
        universityName: 'bogazici',
      );

      expect(byMail, ['Middle East Technical University']);
      expect(byName.map((e) => e.name).toList(), ['Bogazici University']);
      verify(
        () => remoteConfigService.getValue<String>('universities'),
      ).called(1);
    });

    test('falls back to local asset when Remote Config fails', () async {
      when(
        () => remoteConfigService.getValue<String>('universities'),
      ).thenThrow(Exception('Remote config unavailable'));

      final assetJson = TestHelpers.encodeJson([
        {
          'name': 'Istanbul Technical University',
          'domains': ['itu.edu.tr'],
        },
      ]);

      await TestHelpers.setAssetString(
        assetPath: assetPath,
        content: assetJson,
      );

      final result = await dataSource.getUniversityOfMail(
        'name@itu.edu.tr',
        null,
      );

      expect(result, ['Istanbul Technical University']);
      verify(() => loggingService.error(any())).called(greaterThanOrEqualTo(1));
    });

    test(
      'returns empty list for invalid e-mail before initialization',
      () async {
        final result = await dataSource.getUniversityOfMail(
          'invalid-email',
          null,
        );

        expect(result, isEmpty);
        verifyNever(() => remoteConfigService.getValue<String>('universities'));
      },
    );
  });
}
