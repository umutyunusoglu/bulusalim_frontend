// data/feed/sources/idea_feed_source.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:outnest/core/utils/collections/list_chunk_extension.dart';
import 'package:outnest/core/utils/logging/logging_service.dart';
import 'package:outnest/core/utils/types/enums/feed_type.dart';
import 'package:outnest/data/models/idea/idea_model.dart';
import 'package:outnest/domain/entities/feed/feed_entity.dart';
import 'package:outnest/domain/entities/feed/idea/idea_entity.dart';
import 'package:outnest/domain/entities/feed/sources/feed_source.dart';
import 'package:outnest/domain/services/session_service.dart';

/// Feed source for [IdeaEntity] items.
///
/// Mirrors [PostFeedSource] for the query side (public/friends/uni,
/// pagination cursor, blocked-user filtering) but adds a vote
/// enrichment step: after the batch is fetched, the current user's
/// vote document is looked up for every idea in a single chunked
/// `whereIn` query and joined into the entity. This lets the feed
/// card render the correct like/dislike state without a per-card
/// round-trip.
///
/// Implements [LiveFeedSource] so the detail page (and any expanded
/// card) can subscribe to live counter updates as votes and comments
/// come in.
class IdeaFeedSource implements FeedSource, LiveFeedSource<IdeaEntity> {
  IdeaFeedSource({
    required FirebaseFirestore firestore,
    required LoggingService logger,
    required SessionService sessionService,
  }) : _firestore = firestore,
       _logger = logger,
       _sessionService = sessionService;

  final FirebaseFirestore _firestore;
  final LoggingService _logger;
  final SessionService _sessionService;

  DocumentSnapshot? _cursor;

  @override
  Future<List<FeedEntity>> fetch({
    required FeedFetchContext context,
    required int limit,
  }) async {
    if (context.feedType == FeedType.university &&
        context.user.university == null) {
      _logger.info(
        '⚠️ University feed requested but user has no university. '
        'Returning empty idea batch.',
      );
      return [];
    }

    final docs = context.feedType == FeedType.friendsOnly
        ? await _fetchFriendsIdeas(context, limit)
        : await _fetchPublicIdeas(context, limit);

    if (docs.isNotEmpty) _cursor = docs.last;

    return _mapFilterAndEnrich(docs, context);
  }

  @override
  void reset() {
    _cursor = null;
  }

  // --- LiveFeedSource ---

  @override
  Stream<IdeaEntity> liveStream(String id) {
    return _firestore.collection('ideas').doc(id).snapshots().asyncMap((
      doc,
    ) async {
      if (!doc.exists) {
        throw Exception('Idea Deleted');
      }
      final model = IdeaModel.fromFirestore(doc.data()!);
      if (model.isDeleted) throw Exception('Idea Deleted');
      // Live stream is typically subscribed by a logged-in user
      // viewing the idea; resolve their current vote.
      final vote = await _fetchUserVote(id);
      return model.toEntity(currentUserVote: vote);
    });
  }

  // --- Query strategies ---

  Future<List<DocumentSnapshot>> _fetchPublicIdeas(
    FeedFetchContext context,
    int limit,
  ) async {
    var query = _firestore
        .collection('ideas')
        .orderBy('createdAt', descending: true)
        .where('status', isEqualTo: IdeaModel.statusActive);

    if (context.feedType == FeedType.university) {
      query = query.where(
        'creator.university',
        isEqualTo: context.user.university,
      );
    }

    if (_cursor != null) {
      query = query.startAfterDocument(_cursor!);
    }

    return (await query.limit(limit).get()).docs;
  }

  /// Friends-only ideas must be fetched in chunks of 30 because
  /// Firestore's `whereIn` operator caps at 30 values. Status filter
  /// happens client-side to avoid the disallowed double-`whereIn`
  /// query (mirrors [EventFeedSource]'s approach).
  Future<List<DocumentSnapshot>> _fetchFriendsIdeas(
    FeedFetchContext context,
    int limit,
  ) async {
    if (context.followeeIds.isEmpty) return [];

    DateTime? lastDate;
    if (_cursor != null) {
      final data = _cursor!.data()! as Map<String, dynamic>;
      lastDate = (data['createdAt'] as Timestamp).toDate();
    }

    final chunks = context.followeeIds.chunked(30);
    final futures = chunks.map((chunk) {
      var query = _firestore
          .collection('ideas')
          .where('creator.userID', whereIn: chunk)
          .orderBy('createdAt', descending: true);

      if (lastDate != null) {
        query = query.startAfter([Timestamp.fromDate(lastDate)]);
      }
      return query.limit(limit).get();
    });

    final snapshots = await Future.wait(futures);
    final allDocs =
        snapshots.expand((s) => s.docs).where((doc) {
          final status = doc.data()['status'] as String?;
          return status == IdeaModel.statusActive || status == null;
        }).toList()..sort((a, b) {
          final tA = a.data()['createdAt'] as Timestamp;
          final tB = b.data()['createdAt'] as Timestamp;
          return tB.compareTo(tA);
        });

    return allDocs.length > limit ? allDocs.sublist(0, limit) : allDocs;
  }

  // --- Mapping, filtering, vote enrichment ---

  Future<List<FeedEntity>> _mapFilterAndEnrich(
    List<DocumentSnapshot> docs,
    FeedFetchContext context,
  ) async {
    // 1. Filter by blocked users and map to models.
    final models = <IdeaModel>[];
    for (final doc in docs) {
      final data = doc.data()! as Map<String, dynamic>;
      final creatorId =
          (data['creator'] as Map<String, dynamic>)['userID'] as String;

      if (context.blockedIds.contains(creatorId)) {
        _logger.info('🚫 Filtering out idea from blocked user: $creatorId');
        continue;
      }

      models.add(IdeaModel.fromFirestore(data));
    }

    if (models.isEmpty) return [];

    // 2. Batch-fetch the current user's vote on every idea.
    final votesByIdeaId = await _fetchUserVotesForIdeas(
      ideaIds: models.map((m) => m.id).toList(),
      userId: context.user.userID,
    );

    // 3. Materialize entities with vote state joined in.
    return [
      for (final model in models)
        model.toEntity(currentUserVote: votesByIdeaId[model.id]),
    ];
  }

  /// Looks up the current user's vote for each idea in [ideaIds].
  ///
  /// The vote doc id equals the user's id, so each lookup is a
  /// direct doc read. Reads are parallelized via [Future.wait]; the
  /// fan-out is bounded by the feed page size (typically ≤ 20).
  Future<Map<String, IdeaVoteType>> _fetchUserVotesForIdeas({
    required List<String> ideaIds,
    required String userId,
  }) async {
    if (ideaIds.isEmpty) return const {};

    final futures = ideaIds.map((ideaId) async {
      final doc = await _firestore
          .collection('ideas')
          .doc(ideaId)
          .collection('votes')
          .doc(userId)
          .get();
      if (!doc.exists) return MapEntry<String, IdeaVoteType?>(ideaId, null);
      final type = IdeaVoteType.fromString(doc.data()?['type'] as String?);
      return MapEntry<String, IdeaVoteType?>(ideaId, type);
    });

    final entries = await Future.wait(futures);
    return {
      for (final e in entries)
        if (e.value != null) e.key: e.value!,
    };
  }

  /// Single-idea version of [_fetchUserVotesForIdeas], used by the
  /// live stream. Resolves the current user via [SessionService];
  /// returns null if there is no logged-in user.
  Future<IdeaVoteType?> _fetchUserVote(String ideaId) async {
    final userId = _sessionService.currentState.user?.userID;
    if (userId == null) return null;

    final doc = await _firestore
        .collection('ideas')
        .doc(ideaId)
        .collection('votes')
        .doc(userId)
        .get();
    if (!doc.exists) return null;
    return IdeaVoteType.fromString(doc.data()?['type'] as String?);
  }

  @override
  Type get entityType => IdeaEntity;
}
