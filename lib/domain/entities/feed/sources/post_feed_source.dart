// data/feed/sources/post_feed_source.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:outnest/core/utils/collections/list_chunk_extension.dart';
import 'package:outnest/core/utils/logging/logging_service.dart';
import 'package:outnest/core/utils/types/enums/feed_type.dart';
import 'package:outnest/data/models/post/post_model.dart';
import 'package:outnest/domain/entities/feed/feed_entity.dart';
import 'package:outnest/domain/entities/feed/post/post_entity.dart';
import 'package:outnest/domain/entities/feed/sources/feed_source.dart';

/// Feed source for [PostEntity] items.
///
/// Owns the Firestore query for the `posts` collection, its own
/// pagination cursor, and applies the blocked-user filter before
/// returning entities to the repository.
class PostFeedSource implements FeedSource {
  PostFeedSource({
    required FirebaseFirestore firestore,
    required LoggingService logger,
  }) : _firestore = firestore,
       _logger = logger;

  final FirebaseFirestore _firestore;
  final LoggingService _logger;

  DocumentSnapshot? _cursor;

  @override
  Future<List<FeedEntity>> fetch({
    required FeedFetchContext context,
    required int limit,
  }) async {
    // University feed is meaningless without a university on the user.
    if (context.feedType == FeedType.university &&
        context.user.university == null) {
      _logger.info(
        '⚠️ University feed requested but user has no university. '
        'Returning empty post batch.',
      );
      return [];
    }

    final docs = context.feedType == FeedType.friendsOnly
        ? await _fetchFriendsPosts(context, limit)
        : await _fetchPublicPosts(context, limit);

    if (docs.isNotEmpty) _cursor = docs.last;

    return _mapAndFilter(docs, context);
  }

  @override
  void reset() {
    _cursor = null;
  }

  // --- Query strategies ---

  Future<List<DocumentSnapshot>> _fetchPublicPosts(
    FeedFetchContext context,
    int limit,
  ) async {
    var query = _firestore
        .collection('posts')
        .orderBy('createdAt', descending: true);

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

  /// Friends-only posts must be fetched in chunks of 30 because
  /// Firestore's `whereIn` operator caps at 30 values.
  Future<List<DocumentSnapshot>> _fetchFriendsPosts(
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
          .collection('posts')
          .where('creator.userID', whereIn: chunk)
          .orderBy('createdAt', descending: true);

      if (lastDate != null) {
        query = query.startAfter([Timestamp.fromDate(lastDate)]);
      }
      return query.limit(limit).get();
    });

    final snapshots = await Future.wait(futures);
    final allDocs = snapshots.expand((s) => s.docs).toList()
      ..sort((a, b) {
        final tA = a.data()['createdAt'] as Timestamp;
        final tB = b.data()['createdAt'] as Timestamp;
        return tB.compareTo(tA);
      });

    return allDocs.length > limit ? allDocs.sublist(0, limit) : allDocs;
  }

  // --- Mapping & filtering ---

  List<FeedEntity> _mapAndFilter(
    List<DocumentSnapshot> docs,
    FeedFetchContext context,
  ) {
    final result = <FeedEntity>[];
    for (final doc in docs) {
      final data = doc.data()! as Map<String, dynamic>;
      final creatorId =
          (data['creator'] as Map<String, dynamic>)['userID'] as String;

      if (context.blockedIds.contains(creatorId)) {
        _logger.info('🚫 Filtering out post from blocked user: $creatorId');
        continue;
      }

      result.add(PostModel.fromFirestore(data).toEntity());
    }
    return result;
  }
}
