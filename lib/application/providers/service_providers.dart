import 'package:bulusalim/core/utils/logging/logging_service.dart';
import 'package:bulusalim/core/utils/logging/logging_service_impl.dart';
import 'package:bulusalim/data/services/auth_service_impl.dart';
import 'package:bulusalim/data/services/file_service_impl.dart';
import 'package:bulusalim/data/services/remote_config_service_impl.dart';
import 'package:bulusalim/domain/services/auth_service.dart';
import 'package:bulusalim/domain/services/file_service.dart';
import 'package:bulusalim/domain/services/remote_config_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get_it/get_it.dart';
import 'package:http/http.dart' as http;

extension ServiceModule on GetIt {
  void registerServices() {
    this
      ..registerSingleton<LoggingService>(LoggingServiceImpl())
      ..registerSingleton<http.Client>(http.Client())
      ..registerSingleton<AuthService>(
        AuthServiceImpl(
          logger: this(),
          firebaseAuth: FirebaseAuth.instance,
        ),
      )
      ..registerSingleton<FileService>(
        FileServiceImpl(
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
      );
  }
}
