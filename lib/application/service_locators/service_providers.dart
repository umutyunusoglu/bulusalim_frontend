import 'package:firebase_auth/firebase_auth.dart';
import 'package:get_it/get_it.dart';
import 'package:http/http.dart' as http;
import 'package:outnest/core/utils/logging/logging_service.dart';
import 'package:outnest/core/utils/logging/logging_service_impl.dart';
import 'package:outnest/data/repositories/analytics_service_impl.dart';
import 'package:outnest/data/repositories/global_content_cache_impl.dart';
import 'package:outnest/data/repositories/inbox_repository_impl.dart';
import 'package:outnest/data/services/auth_service_impl.dart';
import 'package:outnest/data/services/event_verification_service_impl.dart';
import 'package:outnest/data/services/file_service_impl.dart';
import 'package:outnest/data/services/persistance_service_impl.dart';
import 'package:outnest/data/services/push_notifications_service_impl.dart';
import 'package:outnest/data/services/remote_config_service_impl.dart';
import 'package:outnest/data/services/security_service_impl.dart';
import 'package:outnest/data/services/session_service_impl.dart';
import 'package:outnest/domain/repositories/inbox_repository.dart';
import 'package:outnest/domain/services/analytics/analytics_service.dart';
import 'package:outnest/domain/services/auth_service.dart';
import 'package:outnest/domain/services/event_verification_service.dart';
import 'package:outnest/domain/services/file_service.dart';
import 'package:outnest/domain/services/global_content_cache.dart';
import 'package:outnest/domain/services/persistance_service.dart';
import 'package:outnest/domain/services/push_notifications_service.dart';
import 'package:outnest/domain/services/remote_config_service.dart';
import 'package:outnest/domain/services/security_service.dart';
import 'package:outnest/domain/services/session_service.dart';

extension ServiceModule on GetIt {
  void registerServices() {
    this
      ..registerLazySingleton<LoggingService>(() => LoggingServiceImpl())
      ..registerLazySingleton<http.Client>(() => http.Client())
      ..registerLazySingleton<AuthService>(
        () => AuthServiceImpl(
          logger: this(),
          firebaseAuth: FirebaseAuth.instance,
        ),
      )
      ..registerLazySingleton<FileService>(
        () => FileServiceImpl(
          storage: this(),
          logger: this(),
        ),
      )
      ..registerSingletonAsync<RemoteConfigService>(
        () async {
          final service = RemoteConfigServiceImpl();
          await service.init();
          return service;
        },
        dependsOn: [],
      )
      ..registerLazySingleton<SessionService>(
        () => SessionServiceImpl(
          authService: this(),
          userRepository: this(),
          logger: this(),
        ),
      )
      ..registerSingleton<GlobalContentCache>(
        GlobalContentCacheImpl(
          logger: this(),
        ),
      )
      ..registerLazySingleton<PersistanceService>(
        () => PersistanceServiceImpl(
          logger: this(),
          box: this(),
        ),
      )
      ..registerSingleton<SecurityService>(
        SecurityServiceImpl(
          firestore: this(),
          logger: this(),
          functions: this(),
        ),
      )
      ..registerLazySingleton<PushNotificationsService>(
        () => PushNotificationsServiceImpl(
          firebaseMessaging: this(),
          logger: this(),
          userRepository: this(),
          sessionService: this(),
        ),
      )
      ..registerLazySingleton<InboxRepository>(() => InboxRepositoryImpl())
      ..registerLazySingleton<AnalyticsService>(
        () => AnalyticsServiceImpl(
          analytics: this(),
          logger: this(),
        ),
      )
      ..registerLazySingleton<EventVerificationService>(
        () => EventVerificationServiceImpl(
          sessionService: this(),
          persistanceService: this(),
          logger: this(),
        ),
      );
  }
}
