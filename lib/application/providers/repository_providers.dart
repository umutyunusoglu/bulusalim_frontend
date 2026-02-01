// lib/application/providers/repository_providers.dart

import 'package:outnest/data/repositories/chat_repository_impl.dart';
import 'package:outnest/data/repositories/event_repository_impl.dart';
import 'package:outnest/data/repositories/feed_repository_impl.dart';
import 'package:outnest/data/repositories/map_repository_impl.dart';
import 'package:outnest/data/repositories/post_repository_impl.dart';
import 'package:outnest/data/repositories/user_repository_impl.dart';
import 'package:outnest/data/services/draft_post_service_impl.dart';
import 'package:outnest/domain/repositories/chat_repository.dart';
import 'package:outnest/domain/repositories/event_repository.dart';
import 'package:outnest/domain/repositories/feed_repository.dart';
import 'package:outnest/domain/repositories/map_repository.dart';
import 'package:outnest/domain/repositories/post_repository.dart';
import 'package:outnest/domain/repositories/user_repository.dart';
import 'package:get_it/get_it.dart';
import 'package:outnest/domain/services/draft_post_service.dart';

extension RepositoryModule on GetIt {
  void registerRepositories() {
    this
      ..registerLazySingleton<UserRepository>(
        () => UserRepositoryImpl(
          firestore: this(),
          logger: this(),
          functions: this(),
        ),
      )
      ..registerLazySingleton<EventRepository>(
        () => EventRepositoryImpl(
          firestore: this(),
          logger: this(),
          globalCache: this(),
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
          eventRepository: this(),
        ),
      )
      ..registerFactory<MapRepository>(
        () => MapRepositoryImpl(
          firestore: this(),
          logger: this(),
          globalCache: this(),
          eventRepository: this(),
        ),
      )
      ..registerLazySingleton<ChatRepository>(
        () => ChatRepositoryImpl(
          firestore: this(),
          logger: this(),
        ),
      )
      ..registerLazySingleton<DraftPostService>(
        () => DraftPostServiceImpl(),
      );
  }
}
