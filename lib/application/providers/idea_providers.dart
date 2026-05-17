// application/providers/idea_providers.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:outnest/application/get_it_service_locators/get_it_init.dart';
import 'package:outnest/core/utils/logging/logging_service.dart';
import 'package:outnest/data/repositories/idea_repository_impl.dart';
import 'package:outnest/domain/entities/feed/idea/idea_comment_entity.dart';
import 'package:outnest/domain/entities/feed/idea/idea_entity.dart';
import 'package:outnest/domain/repositories/idea_repository.dart';
import 'package:outnest/domain/services/session_service.dart';

/// App-wide singleton [IdeaRepository].
///
/// Lives in its own file (rather than `feed_providers.dart`) because
/// ideas have surfaces beyond the feed — the detail page, the
/// create-idea screen, comment tiles — and grouping by feature reads
/// better than grouping by data layer.
final Provider<IdeaRepository> ideaRepositoryProvider =
    Provider<IdeaRepository>((ref) {
      return IdeaRepositoryImpl(
        firestore: getIt<FirebaseFirestore>(),
        logger: getIt<LoggingService>(),
        sessionService: getIt<SessionService>(),
      );
    });

/// Live stream of a single idea. Used by [IdeaDetailPage] to keep
/// counters reactive when other users vote or comment.
///
/// `autoDispose` — once the detail page is popped, the Firestore
/// listener is torn down; no orphaned listeners after navigation.
final ideaStreamProvider = StreamProvider.autoDispose
    .family<IdeaEntity?, String>((ref, ideaId) {
      return ref.watch(ideaRepositoryProvider).watchIdea(ideaId);
    });

/// Live stream of top-level comments under an idea. Replies are
/// fetched lazily by [CommentThread], not through this provider.
final topLevelCommentsProvider = StreamProvider.autoDispose
    .family<List<IdeaCommentEntity>, String>((ref, ideaId) {
      return ref
          .watch(ideaRepositoryProvider)
          .watchComments(
            ideaId: ideaId,
            parentCommentId: null,
          );
    });
