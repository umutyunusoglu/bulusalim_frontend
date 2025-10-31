// lib/application/providers/repository_providers.dart

import 'package:bulusalim/data/datasources/hobby_datasource_impl.dart';
import 'package:bulusalim/data/repositories/event_repository_impl.dart';
import 'package:bulusalim/data/repositories/user_repository_impl.dart';
import 'package:bulusalim/domain/datasources/hobby_datasource.dart';
import 'package:bulusalim/domain/repositories/event_repository.dart';
import 'package:bulusalim/domain/repositories/user_repository.dart';
import 'package:get_it/get_it.dart';

extension RepositoryModule on GetIt {
  void registerRepositories() {
    this
      ..registerSingleton<HobbyDataSource>(const HobbyDataSourceImpl())
      ..registerSingleton<UserRepository>(
        UserRepositoryImpl(
          firestore: this(),
          logger: this(),
        ),
      )
      ..registerSingleton<EventRepository>(
        EventRepositoryImpl(
          firestore: this(),
          logger: this(),
        ),
      );
  }
}
