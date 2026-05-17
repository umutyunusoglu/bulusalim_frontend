// presentation/home/providers/feed_providers.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:outnest/application/get_it_service_locators/get_it_init.dart';
import 'package:outnest/core/utils/logging/logging_service.dart';
import 'package:outnest/core/utils/types/enums/feed_type.dart';
import 'package:outnest/data/repositories/feed_repository_impl.dart';
import 'package:outnest/domain/entities/feed/feed_entity.dart';
import 'package:outnest/domain/entities/feed/sources/event_feed_source.dart';
import 'package:outnest/domain/entities/feed/sources/idea_feed_source.dart';
import 'package:outnest/domain/entities/feed/sources/post_feed_source.dart';
import 'package:outnest/domain/repositories/event_repository.dart';
import 'package:outnest/domain/repositories/feed_repository.dart';
import 'package:outnest/domain/repositories/group_repository.dart';
import 'package:outnest/domain/services/global_content_cache.dart';
import 'package:outnest/domain/services/session_service.dart';

/// Per-tab [FeedRepository]. Each [FeedType] gets its own instance,
/// with its own sources, cursors and stream — so tabs are fully
/// isolated and disposed independently.
final ProviderFamily<FeedRepository, FeedType> feedRepositoryProvider =
    Provider.family<FeedRepository, FeedType>((ref, feedType) {
      final firestore = getIt<FirebaseFirestore>();
      final logger = getIt<LoggingService>();
      final cache = getIt<GlobalContentCache>();
      final sessionService = getIt<SessionService>();
      final eventRepository = getIt<EventRepository>();
      final groupRepository = getIt<GroupRepository>();

      final repository = FeedRepositoryImpl(
        feedType: feedType,
        sources: [
          PostFeedSource(firestore: firestore, logger: logger),
          EventFeedSource(
            firestore: firestore,
            logger: logger,
            eventRepository: eventRepository,
            groupRepository: groupRepository,
            cache: cache,
          ),
          IdeaFeedSource(
            firestore: firestore,
            logger: logger,
            sessionService: sessionService,
          ),
        ],
        logger: logger,
        cache: cache,
      );

      ref.onDispose(repository.dispose);
      repository.warmup();
      return repository;
    });

/// The feed stream the UI watches. Wrapping [FeedRepository.feedStream]
/// in a [StreamProvider] gives us [AsyncValue] for free, so the UI
/// gets loading/error/data handling without manual flags.
final StreamProviderFamily<List<FeedEntity>, FeedType> feedStreamProvider =
    StreamProvider.family<List<FeedEntity>, FeedType>((ref, feedType) {
      final repo = ref.watch(feedRepositoryProvider(feedType));
      return repo.feedStream;
    });
