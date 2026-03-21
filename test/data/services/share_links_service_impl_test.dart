import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/widgets.dart';
import 'package:mocktail/mocktail.dart';
import 'package:outnest/application/service_locators/get_it_init.dart';
import 'package:outnest/data/models/links/deep_link_target.dart';
import 'package:outnest/data/services/share_links_service_impl.dart';
import 'package:outnest/domain/repositories/user_repository.dart';
import 'package:outnest/domain/services/auth_service.dart';
import 'package:outnest/domain/services/session_service.dart';

class _MockAuthService extends Mock implements AuthService {}

class _MockUserRepository extends Mock implements UserRepository {}

class _MockSessionService extends Mock implements SessionService {}

class _MockBuildContext extends Mock implements BuildContext {}

void main() {
  late _MockAuthService authService;
  late _MockUserRepository userRepository;
  late _MockSessionService sessionService;
  late _MockBuildContext context;

  setUp(() async {
    await getIt.reset();

    authService = _MockAuthService();
    userRepository = _MockUserRepository();
    sessionService = _MockSessionService();
    context = _MockBuildContext();

    getIt
      ..registerSingleton<AuthService>(authService)
      ..registerSingleton<UserRepository>(userRepository)
      ..registerSingleton<SessionService>(sessionService);
  });

  tearDown(() async {
    await getIt.reset();
  });

  group('ShareLinksServiceImpl URI builders', () {
    test('post() creates expected share URI', () {
      final uri = ShareLinksServiceImpl.post('post-123');

      expect(uri.toString(), 'https://outnest.app/share/post/post-123');
    });

    test('event() creates expected share URI', () {
      final uri = ShareLinksServiceImpl.event('event-456');

      expect(uri.toString(), 'https://outnest.app/share/event/event-456');
    });

    test('user() creates expected share URI', () {
      final uri = ShareLinksServiceImpl.user('user-789');

      expect(uri.toString(), 'https://outnest.app/share/profile/user-789');
    });
  });

  group('ShareLinksServiceImpl.parseLink', () {
    Future<ShareLinksServiceImpl> createReadyService() async {
      when(() => authService.isUserLoggedIn()).thenAnswer((_) async => true);
      when(() => authService.getCurrentUserID()).thenReturn('user-1');
      when(
        () => userRepository.isUserRegistered('user-1'),
      ).thenAnswer((_) async => true);

      return ShareLinksServiceImpl();
    }

    test('parses post deep link', () async {
      final service = await createReadyService();

      final result = await service.parseLink(
        Uri.parse('https://outnest.app/share/post/post-123'),
        context,
      );

      expect(result, isNotNull);
      expect(result!.type, DeepLinkType.post);
      expect(result.id, 'post-123');
    });

    test('parses event deep link', () async {
      final service = await createReadyService();

      final result = await service.parseLink(
        Uri.parse('https://outnest.app/share/event/event-456'),
        context,
      );

      expect(result, isNotNull);
      expect(result!.type, DeepLinkType.event);
      expect(result.id, 'event-456');
    });

    test('parses profile deep link', () async {
      final service = await createReadyService();

      final result = await service.parseLink(
        Uri.parse('https://outnest.app/share/profile/user-789'),
        context,
      );

      expect(result, isNotNull);
      expect(result!.type, DeepLinkType.profile);
      expect(result.id, 'user-789');
    });

    test('returns unknown for non-share domain', () async {
      final service = await createReadyService();

      final result = await service.parseLink(
        Uri.parse('https://example.com/share/post/post-123'),
        context,
      );

      expect(result, isNotNull);
      expect(result!.type, DeepLinkType.unknown);
      expect(result.id, isNull);
    });

    test('returns unknown for unsupported share type', () async {
      final service = await createReadyService();

      final result = await service.parseLink(
        Uri.parse('https://outnest.app/share/group/group-1'),
        context,
      );

      expect(result, isNotNull);
      expect(result!.type, DeepLinkType.unknown);
      expect(result.id, isNull);
    });

    test('returns unknown for incomplete share path', () async {
      final service = await createReadyService();

      final result = await service.parseLink(
        Uri.parse('https://outnest.app/share'),
        context,
      );

      expect(result, isNotNull);
      expect(result!.type, DeepLinkType.unknown);
      expect(result.id, isNull);
    });
  });
}
