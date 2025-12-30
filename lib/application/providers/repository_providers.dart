// lib/application/providers/repository_providers.dart

import 'package:bulusalim/data/repositories/chat_repository_impl.dart';
import 'package:bulusalim/data/repositories/event_repository_impl.dart';
import 'package:bulusalim/data/repositories/feed_repository_impl.dart';
import 'package:bulusalim/data/repositories/map_repository_impl.dart';
import 'package:bulusalim/data/repositories/post_repository_impl.dart';
import 'package:bulusalim/data/repositories/user_repository_impl.dart';
import 'package:bulusalim/domain/repositories/chat_repository.dart';
import 'package:bulusalim/domain/repositories/event_repository.dart';
import 'package:bulusalim/domain/repositories/feed_repository.dart';
import 'package:bulusalim/domain/repositories/map_repository.dart';
import 'package:bulusalim/domain/repositories/post_repository.dart';
import 'package:bulusalim/domain/repositories/user_repository.dart';
import 'package:get_it/get_it.dart';

extension RepositoryModule on GetIt {
  void registerRepositories() {
    this
      ..registerLazySingleton<UserRepository>(
        () => UserRepositoryImpl(
          firestore: this(),
          logger: this(),
        ),
      )
      ..registerLazySingleton<EventRepository>(
        () => EventRepositoryImpl(
          firestore: this(),
          logger: this(),
        ),
      )
      ..registerLazySingleton<PostRepository>(
        () => PostRepositoryImpl(
          firestore: this(),
          logger: this(),
        ),
      )
      ..registerFactory<FeedRepository>(
        () => FeedRepositoryImpl(
          firestore: this(),
          logger: this(),
          cache: this(),
        ),
      )
      ..registerFactory<MapRepository>(
        () => MapRepositoryImpl(
          firestore: this(),
          logger: this(),
          globalCache: this(),
        ),
      )
      ..registerLazySingleton<ChatRepository>(
        () => ChatRepositoryImpl(
          firestore: this(),
          logger: this(),
        ),
      );
  }
}
