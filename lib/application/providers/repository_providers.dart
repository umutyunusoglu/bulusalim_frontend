// lib/application/providers/repository_providers.dart

import 'package:bulusalim/data/repositories/event_repository_impl.dart';
import 'package:bulusalim/data/repositories/feed_repository_impl.dart';
import 'package:bulusalim/data/repositories/post_repository_impl.dart';
import 'package:bulusalim/data/repositories/user_repository_impl.dart';
import 'package:bulusalim/domain/repositories/event_repository.dart';
import 'package:bulusalim/domain/repositories/feed_repository.dart';
import 'package:bulusalim/domain/repositories/post_repository.dart';
import 'package:bulusalim/domain/repositories/user_repository.dart';
import 'package:get_it/get_it.dart';

extension RepositoryModule on GetIt {
  void registerRepositories() {
    this
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
      )
      ..registerSingleton<PostRepository>(
        PostRepositoryImpl(
          firestore: this(),
          logger: this(),
        ),
      )
      ..registerSingleton<FeedRepository>(
        FeedRepositoryImpl(
          firestore: this(),
          logger: this(),
        ),
      );
  }
}
