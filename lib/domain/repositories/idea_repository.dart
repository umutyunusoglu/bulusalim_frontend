// domain/repositories/idea_repository.dart

import 'package:outnest/domain/entities/feed/idea/idea_comment_entity.dart';
import 'package:outnest/domain/entities/feed/idea/idea_entity.dart';

/// Repository for [IdeaEntity] and its comment thread.
///
/// Voting is mutually exclusive: calling [setVote] with a type the
/// user already has will clear it (toggle), and switching from like
/// to dislike (or vice versa) is a single atomic operation on the
/// vote document. The repository updates the per-idea counters in
/// the same transaction so the UI sees consistent numbers.
///
/// Comment loading is intentionally branch-scoped — there is no
/// "fetch entire thread" call. The UI walks the tree by repeatedly
/// asking for the children of a given comment, keeping deep threads
/// cheap even with no depth cap.
abstract class IdeaRepository {
  /// Creates a new idea authored by the current user.
  /// Returns the created entity (with server-assigned id/timestamps).
  Future<IdeaEntity> createIdea({
    required String content,
    required bool commentsEnabled,
  });

  /// Fetches a single idea by id. Used by the detail page and as a
  /// fallback when an idea is referenced but not in the feed cache.
  Future<IdeaEntity?> getIdea(String ideaId);

  /// Live stream of a single idea (counters, commentsEnabled flag,
  /// edits). Used by the detail page header and by the feed card
  /// when subscribed via the [LiveFeedSource] interface.
  Stream<IdeaEntity> watchIdea(String ideaId);

  /// Sets, switches, or clears the current user's vote.
  ///
  /// Passing the same [type] the user already has clears the vote.
  /// Passing the opposite type switches it. Counter updates on the
  /// parent idea happen atomically with the vote write.
  Future<void> setVote({
    required String ideaId,
    required IdeaVoteType type,
  });

  /// Fetches one page of comments under [parentCommentId].
  ///
  /// Pass `parentCommentId: null` to get top-level comments on the
  /// idea. [cursor] is the last comment's id from the previous page,
  /// or null for the first page.
  Future<List<IdeaCommentEntity>> getComments({
    required String ideaId,
    required String? parentCommentId,
    String? cursor,
    int limit = 20,
  });

  /// Live stream of comments under [parentCommentId]. The stream
  /// emits the full current page whenever any comment in it changes,
  /// so the UI can re-render in place when counters update.
  Stream<List<IdeaCommentEntity>> watchComments({
    required String ideaId,
    required String? parentCommentId,
    int limit = 20,
  });

  /// Posts a new comment. Pass [parentCommentId] to reply to another
  /// comment; pass null to post a top-level comment on the idea.
  /// Updates the parent's [replyCount] (or the idea's [commentCount])
  /// atomically.
  Future<IdeaCommentEntity> addComment({
    required String ideaId,
    required String? parentCommentId,
    required String content,
  });

  /// Vote on a comment. Same toggle/switch semantics as [setVote].
  Future<void> setCommentVote({
    required String ideaId,
    required String commentId,
    required IdeaVoteType type,
  });

  /// Soft-deletes an idea. The document is kept with `status: deleted`
  /// so existing comments still have a parent reference.
  Future<void> deleteIdea(String ideaId);

  /// Soft-deletes a comment, preserving its position in the thread.
  Future<void> deleteComment({
    required String ideaId,
    required String commentId,
  });
}
