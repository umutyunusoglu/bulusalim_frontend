import 'package:bulusalim/core/utils/logging/logging_service.dart';
import 'package:bulusalim/core/utils/logging/logging_service_impl.dart';
import 'package:bulusalim/data/repositories/global_content_cache_impl.dart';
import 'package:bulusalim/data/services/auth_service_impl.dart';
import 'package:bulusalim/data/services/file_service_impl.dart';
import 'package:bulusalim/data/services/persistance_service_impl.dart';
import 'package:bulusalim/data/services/remote_config_service_impl.dart';
import 'package:bulusalim/data/services/session_service_impl.dart';
import 'package:bulusalim/domain/services/auth_service.dart';
import 'package:bulusalim/domain/services/file_service.dart';
import 'package:bulusalim/domain/services/global_content_cache.dart';
import 'package:bulusalim/domain/services/persistance_service.dart';
import 'package:bulusalim/domain/services/remote_config_service.dart';
import 'package:bulusalim/domain/services/session_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get_it/get_it.dart';
import 'package:http/http.dart' as http;

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
      );
  }
}
