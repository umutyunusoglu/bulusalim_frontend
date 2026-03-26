import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/widgets.dart';
import 'package:mocktail/mocktail.dart';
import 'package:outnest/application/get_it_service_locators/get_it_init.dart';
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
}
