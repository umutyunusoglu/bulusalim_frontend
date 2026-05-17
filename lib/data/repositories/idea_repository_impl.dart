// data/repositories/idea_repository_impl.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:outnest/core/utils/logging/logging_service.dart';
import 'package:outnest/core/utils/types/types.dart';
import 'package:outnest/data/models/idea/idea_comment_model.dart';
import 'package:outnest/data/models/idea/idea_model.dart';
import 'package:outnest/domain/entities/feed/idea/idea_comment_entity.dart';
import 'package:outnest/domain/entities/feed/idea/idea_entity.dart';
import 'package:outnest/domain/entities/user/compact_user_entity.dart';
import 'package:outnest/domain/entities/user/user_entity.dart';
import 'package:outnest/domain/repositories/idea_repository.dart';
import 'package:outnest/domain/services/session_service.dart';

/// Firestore-backed [IdeaRepository].
///
/// Vote writes always go through a transaction so the per-idea
/// counters and the user's vote document stay consistent — there is
/// no scenario where `likeCount` reflects a vote that isn't in the
/// votes subcollection, or vice versa.
///
/// Comment writes are batched: the comment document plus the
/// parent's `replyCount` (or the idea's `commentCount`) are updated
/// in a single atomic commit. Soft deletes preserve thread
/// structure: deleted comments stay in place with `status: deleted`
/// so their replies still have a parent to point at.
class IdeaRepositoryImpl implements IdeaRepository {
  IdeaRepositoryImpl({
    required FirebaseFirestore firestore,
    required LoggingService logger,
    required SessionService sessionService,
  }) : _firestore = firestore,
       _logger = logger,
       _sessionService = sessionService;

  final FirebaseFirestore _firestore;
  final LoggingService _logger;
  final SessionService _sessionService;

  CollectionReference<Map<String, dynamic>> get _ideas =>
      _firestore.collection('ideas');

  DocumentReference<Map<String, dynamic>> _ideaDoc(Identifier id) =>
      _ideas.doc(id);

  CollectionReference<Map<String, dynamic>> _commentsOf(Identifier ideaId) =>
      _ideaDoc(ideaId).collection('comments');

  CollectionReference<Map<String, dynamic>> _votesOf(Identifier ideaId) =>
      _ideaDoc(ideaId).collection('votes');

  CollectionReference<Map<String, dynamic>> _commentVotesOf({
    required Identifier ideaId,
    required Identifier commentId,
  }) => _commentsOf(ideaId).doc(commentId).collection('votes');

  // --- Creation ---

  @override
  Future<IdeaEntity> createIdea({
    required String content,
    required bool commentsEnabled,
  }) async {
    final user = _requireUser();
    final compactUser = _compactFromCurrentUser(user);

    final docRef = _ideas.doc();
    final now = DateTime.now();
    final model = IdeaModel(
      id: docRef.id,
      creator: compactUser,
      content: content,
      createdAt: now,
      updatedAt: null,
      likeCount: 0,
      dislikeCount: 0,
      commentCount: 0,
      commentsEnabled: commentsEnabled,
      status: IdeaModel.statusActive,
    );

    await docRef.set(model.toFirestore());
    _logger.info('💡 Idea created: ${docRef.id}');

    return model.toEntity();
  }

  @override
  Future<IdeaEntity?> getIdea(String ideaId) async {
    final doc = await _ideaDoc(ideaId).get();
    if (!doc.exists) return null;

    final model = IdeaModel.fromFirestore(doc.data()!);
    if (model.isDeleted) return null;

    final vote = await _fetchCurrentUserVoteOnIdea(ideaId);
    return model.toEntity(currentUserVote: vote);
  }

  @override
  Stream<IdeaEntity> watchIdea(String ideaId) {
    return _ideaDoc(ideaId).snapshots().asyncMap((doc) async {
      if (!doc.exists) throw Exception('Idea not found');
      final model = IdeaModel.fromFirestore(doc.data()!);
      if (model.isDeleted) throw Exception('Idea deleted');

      final vote = await _fetchCurrentUserVoteOnIdea(ideaId);
      return model.toEntity(currentUserVote: vote);
    });
  }

  // --- Voting (idea) ---

  @override
  Future<void> setVote({
    required String ideaId,
    required IdeaVoteType type,
  }) async {
    final user = _requireUser();
    await _firestore.runTransaction((tx) async {
      final ideaRef = _ideaDoc(ideaId);
      final voteRef = _votesOf(ideaId).doc(user.userID);

      final ideaSnap = await tx.get(ideaRef);
      if (!ideaSnap.exists) throw Exception('Idea not found');
      final voteSnap = await tx.get(voteRef);

      final existing = voteSnap.exists
          ? IdeaVoteType.fromString(voteSnap.data()?['type'] as String?)
          : null;

      _applyVoteDelta(
        tx: tx,
        parentRef: ideaRef,
        voteRef: voteRef,
        existing: existing,
        next: type,
      );
    });
    _logger.info('👍 Idea vote set: $ideaId → $type');
  }

  // --- Comments ---

  @override
  Future<List<IdeaCommentEntity>> getComments({
    required String ideaId,
    required String? parentCommentId,
    String? cursor,
    int limit = 20,
  }) async {
    final query = _commentsQuery(
      ideaId: ideaId,
      parentCommentId: parentCommentId,
      limit: limit,
    );

    final paginated = cursor == null
        ? query
        : query.startAfterDocument(await _commentsOf(ideaId).doc(cursor).get());

    final snap = await paginated.get();
    return _hydrateComments(ideaId: ideaId, docs: snap.docs);
  }

  @override
  Stream<List<IdeaCommentEntity>> watchComments({
    required String ideaId,
    required String? parentCommentId,
    int limit = 20,
  }) {
    final query = _commentsQuery(
      ideaId: ideaId,
      parentCommentId: parentCommentId,
      limit: limit,
    );

    return query.snapshots().asyncMap(
      (snap) => _hydrateComments(ideaId: ideaId, docs: snap.docs),
    );
  }

  @override
  Future<IdeaCommentEntity> addComment({
    required String ideaId,
    required String? parentCommentId,
    required String content,
  }) async {
    final user = _requireUser();
    final compactUser = _compactFromCurrentUser(user);

    final commentRef = _commentsOf(ideaId).doc();
    final now = DateTime.now();

    final model = IdeaCommentModel(
      id: commentRef.id,
      ideaId: ideaId,
      author: compactUser,
      content: content,
      parentCommentId: parentCommentId, // null for top-level
      createdAt: now,
      updatedAt: null,
      likeCount: 0,
      dislikeCount: 0,
      replyCount: 0,
      status: IdeaCommentModel.statusActive,
    );

    // The comment document and the parent counter must move
    // together. Use a batch — same atomicity as a transaction here
    // since we're only writing, not conditionally reading first.
    //
    // `model.toFirestore()` writes the `__root__` sentinel for
    // null parentCommentId, so `_commentsQuery` can rely on a
    // simple `whereEqualTo` instead of Firestore's flaky
    // null-equality behavior.
    final batch = _firestore.batch();
    batch.set(commentRef, model.toFirestore());

    if (parentCommentId == null) {
      // Top-level → bump idea.commentCount.
      batch.update(_ideaDoc(ideaId), {
        'commentCount': FieldValue.increment(1),
      });
    } else {
      // Reply → bump parent comment.replyCount AND the idea's
      // overall commentCount (UI shows total comment count on the
      // card regardless of depth).
      batch.update(_commentsOf(ideaId).doc(parentCommentId), {
        'replyCount': FieldValue.increment(1),
      });
      batch.update(_ideaDoc(ideaId), {
        'commentCount': FieldValue.increment(1),
      });
    }

    await batch.commit();
    _logger.info(
      '💬 Comment added on $ideaId '
      '(parent: ${parentCommentId ?? "<top>"})',
    );

    return model.toEntity();
  }

  // --- Voting (comment) ---

  @override
  Future<void> setCommentVote({
    required String ideaId,
    required String commentId,
    required IdeaVoteType type,
  }) async {
    final user = _requireUser();
    await _firestore.runTransaction((tx) async {
      final commentRef = _commentsOf(ideaId).doc(commentId);
      final voteRef = _commentVotesOf(
        ideaId: ideaId,
        commentId: commentId,
      ).doc(user.userID);

      final commentSnap = await tx.get(commentRef);
      if (!commentSnap.exists) throw Exception('Comment not found');
      final voteSnap = await tx.get(voteRef);

      final existing = voteSnap.exists
          ? IdeaVoteType.fromString(voteSnap.data()?['type'] as String?)
          : null;

      _applyVoteDelta(
        tx: tx,
        parentRef: commentRef,
        voteRef: voteRef,
        existing: existing,
        next: type,
      );
    });
    _logger.info('👍 Comment vote set: $commentId → $type');
  }

  // --- Soft delete ---

  @override
  Future<void> deleteIdea(String ideaId) async {
    await _ideaDoc(ideaId).update({
      'status': IdeaModel.statusDeleted,
      'updatedAt': Timestamp.now(),
    });
    _logger.info('🗑️ Idea soft-deleted: $ideaId');
  }

  @override
  Future<void> deleteComment({
    required String ideaId,
    required String commentId,
  }) async {
    await _commentsOf(ideaId).doc(commentId).update({
      'status': IdeaCommentModel.statusDeleted,
      'updatedAt': Timestamp.now(),
    });
    _logger.info('🗑️ Comment soft-deleted: $commentId');
  }

  // --- Internals ---

  /// Shared core for the vote toggle/switch logic. Handles all four
  /// cases in one place so idea-level and comment-level voting stay
  /// in sync forever:
  ///
  ///   - no existing vote, new vote     → write vote, +1 next-side
  ///   - same vote already exists       → delete vote, -1 same-side
  ///   - opposite vote exists           → write vote, -1 opp, +1 next
  ///   - (nothing → nothing) impossible by contract
  void _applyVoteDelta({
    required Transaction tx,
    required DocumentReference<Map<String, dynamic>> parentRef,
    required DocumentReference<Map<String, dynamic>> voteRef,
    required IdeaVoteType? existing,
    required IdeaVoteType next,
  }) {
    final likeField = 'likeCount';
    final dislikeField = 'dislikeCount';

    if (existing == null) {
      tx.set(voteRef, {
        'type': next.value,
        'createdAt': Timestamp.now(),
      });
      tx.update(parentRef, {
        next == IdeaVoteType.like ? likeField : dislikeField:
            FieldValue.increment(1),
      });
      return;
    }

    if (existing == next) {
      // Toggle off.
      tx.delete(voteRef);
      tx.update(parentRef, {
        next == IdeaVoteType.like ? likeField : dislikeField:
            FieldValue.increment(-1),
      });
      return;
    }

    // Switch sides.
    tx.set(voteRef, {
      'type': next.value,
      'createdAt': Timestamp.now(),
    });
    tx.update(parentRef, {
      next == IdeaVoteType.like ? likeField : dislikeField:
          FieldValue.increment(1),
      existing == IdeaVoteType.like ? likeField : dislikeField:
          FieldValue.increment(-1),
    });
  }

  Query<Map<String, dynamic>> _commentsQuery({
    required String ideaId,
    required String? parentCommentId,
    required int limit,
  }) {
    // Firestore's `whereEqualTo(null)` query is unreliable on
    // nullable fields — it cannot consistently distinguish
    // "field is null" from "field is missing", and combined with
    // orderBy it can return replies in the top-level list (which
    // produced the bug where a reply showed up twice: once nested,
    // once at root).
    //
    // We sidestep the issue by writing a sentinel
    // ([IdeaCommentModel.rootParentId]) for top-level comments
    // instead of null. The domain entity still exposes
    // `parentCommentId` as nullable; the conversion happens at the
    // wire layer only.
    return _commentsOf(ideaId)
        .where(
          'parentCommentId',
          isEqualTo: parentCommentId ?? IdeaCommentModel.rootParentId,
        )
        .orderBy('createdAt')
        .limit(limit);
  }

  Future<List<IdeaCommentEntity>> _hydrateComments({
    required String ideaId,
    required List<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
  }) async {
    if (docs.isEmpty) return const [];

    final models = [
      for (final doc in docs)
        IdeaCommentModel.fromFirestore(data: doc.data(), ideaId: ideaId),
    ];

    final votes = await _fetchCurrentUserCommentVotes(
      ideaId: ideaId,
      commentIds: models.map((m) => m.id).toList(),
    );

    return [
      for (final model in models)
        model.toEntity(currentUserVote: votes[model.id]),
    ];
  }

  Future<IdeaVoteType?> _fetchCurrentUserVoteOnIdea(String ideaId) async {
    final userId = _sessionService.currentState.user?.userID;
    if (userId == null) return null;

    final doc = await _votesOf(ideaId).doc(userId).get();
    if (!doc.exists) return null;
    return IdeaVoteType.fromString(doc.data()?['type'] as String?);
  }

  Future<Map<String, IdeaVoteType>> _fetchCurrentUserCommentVotes({
    required String ideaId,
    required List<String> commentIds,
  }) async {
    final userId = _sessionService.currentState.user?.userID;
    if (userId == null || commentIds.isEmpty) return const {};

    final futures = commentIds.map((commentId) async {
      final doc = await _commentVotesOf(
        ideaId: ideaId,
        commentId: commentId,
      ).doc(userId).get();
      if (!doc.exists) return MapEntry<String, IdeaVoteType?>(commentId, null);
      final type = IdeaVoteType.fromString(doc.data()?['type'] as String?);
      return MapEntry<String, IdeaVoteType?>(commentId, type);
    });

    final entries = await Future.wait(futures);
    return {
      for (final e in entries)
        if (e.value != null) e.key: e.value!,
    };
  }

  /// Builds the [CompactUserEntity] snapshot embedded in idea and
  /// comment documents. Kept in one place so both writes stay in
  /// sync if the snapshot shape changes.
  CompactUserEntity _compactFromCurrentUser(UserEntity user) {
    return CompactUserEntity(
      userID: user.userID,
      username: user.username,
      profileImageUrl: user.profileImageUrl,
      city: user.city,
      university: user.university,
      nameSurname: user.nameSurname,
      isPrivate: user.isPrivate,
      bio: user.bio,
      accountType: user.accountType,
      communityData: user.communityData,
      verifiedEventCount: user.verifiedEventCount,
    );
  }

  UserEntity _requireUser() {
    final user = _sessionService.currentState.user;
    if (user == null) throw StateError('No authenticated user');
    return user;
  }
}
