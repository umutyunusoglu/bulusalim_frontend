// data/feed/sources/event_feed_source.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:outnest/core/utils/collections/list_chunk_extension.dart';
import 'package:outnest/core/utils/logging/logging_service.dart';
import 'package:outnest/core/utils/types/enums/feed_type.dart';
import 'package:outnest/core/utils/types/enums/visibility_enum.dart';
import 'package:outnest/data/models/event/event_model.dart';
import 'package:outnest/domain/entities/feed/event/event_entity.dart';
import 'package:outnest/domain/entities/feed/feed_entity.dart';
import 'package:outnest/domain/entities/feed/sources/feed_source.dart';
import 'package:outnest/domain/repositories/event_repository.dart';
import 'package:outnest/domain/repositories/group_repository.dart';
import 'package:outnest/domain/services/global_content_cache.dart';

/// Feed source for [EventEntity] items.
///
/// Owns the Firestore query for the `events` collection (with status
/// and lock filters), pagination cursor, blocked-user filtering,
/// per-event visibility checks, and enrichment with live details
/// (participant counts, etc.) before items reach the UI.
///
/// Also implements [LiveFeedSource] because event details such as
/// participant count must stay reactive after the item is rendered.
class EventFeedSource implements FeedSource, LiveFeedSource<EventEntity> {
  EventFeedSource({
    required FirebaseFirestore firestore,
    required LoggingService logger,
    required EventRepository eventRepository,
    required GroupRepository groupRepository,
    required GlobalContentCache cache,
  }) : _firestore = firestore,
       _logger = logger,
       _eventRepository = eventRepository,
       _groupRepository = groupRepository,
       _cache = cache;

  final FirebaseFirestore _firestore;
  final LoggingService _logger;
  final EventRepository _eventRepository;
  final GroupRepository _groupRepository;
  final GlobalContentCache _cache;

  DocumentSnapshot? _cursor;

  static const _visibleStatuses = ['upcoming', 'ongoing'];

  @override
  Future<List<FeedEntity>> fetch({
    required FeedFetchContext context,
    required int limit,
  }) async {
    if (context.feedType == FeedType.university &&
        context.user.university == null) {
      _logger.info(
        '⚠️ University feed requested but user has no university. '
        'Returning empty event batch.',
      );
      return [];
    }

    final docs = context.feedType == FeedType.friendsOnly
        ? await _fetchFriendsEvents(context, limit)
        : await _fetchPublicEvents(context, limit);

    if (docs.isNotEmpty) _cursor = docs.last;

    return _mapFilterAndEnrich(docs, context);
  }

  @override
  void reset() {
    _cursor = null;
  }

  // --- LiveFeedSource ---

  @override
  Stream<EventEntity> liveStream(String id) {
    return _firestore.collection('events').doc(id).snapshots().asyncMap((
      doc,
    ) async {
      if (!doc.exists) {
        final cached = _cache.getEntity(id);
        if (cached is EventEntity) return cached;
        throw Exception('Event Deleted');
      }
      final entity = EventModel.fromFirestore(doc.data()!).toEntity();
      return _eventRepository.enrichEventWithDetails(entity);
    });
  }

  // --- Query strategies ---

  Future<List<DocumentSnapshot>> _fetchPublicEvents(
    FeedFetchContext context,
    int limit,
  ) async {
    var query = _firestore
        .collection('events')
        .orderBy('createdAt', descending: true)
        .where('status', whereIn: _visibleStatuses)
        .where('isLocked', isEqualTo: false);

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

  /// Friends-only events must be fetched in chunks of 30 because of
  /// Firestore's `whereIn` limit. Status filtering happens client-side
  /// to avoid the disallowed double-`whereIn` query.
  Future<List<DocumentSnapshot>> _fetchFriendsEvents(
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
          .collection('events')
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
          return _visibleStatuses.contains(status);
        }).toList()..sort((a, b) {
          final tA = a.data()['createdAt'] as Timestamp;
          final tB = b.data()['createdAt'] as Timestamp;
          return tB.compareTo(tA);
        });

    return allDocs.length > limit ? allDocs.sublist(0, limit) : allDocs;
  }

  // --- Mapping, filtering, enrichment ---

  Future<List<FeedEntity>> _mapFilterAndEnrich(
    List<DocumentSnapshot> docs,
    FeedFetchContext context,
  ) async {
    final result = <FeedEntity>[];
    for (final doc in docs) {
      final data = doc.data()! as Map<String, dynamic>;
      final creatorId =
          (data['creator'] as Map<String, dynamic>)['userID'] as String;

      if (context.blockedIds.contains(creatorId)) {
        _logger.info('🚫 Filtering out event from blocked user: $creatorId');
        continue;
      }

      final entity = EventModel.fromFirestore(data).toEntity();
      if (!await _canUserSeeEvent(entity, context)) continue;

      final enriched = await _eventRepository.enrichEventWithDetails(entity);
      result.add(enriched);
    }
    return result;
  }

  Future<bool> _canUserSeeEvent(
    EventEntity event,
    FeedFetchContext context,
  ) async {
    final user = context.user;

    // The user can always see their own events.
    if (event.creator.userID == user.userID) return true;

    // On the "all" feed, hide university-scoped events from other schools.
    if (context.feedType == FeedType.all &&
        event.visibility == VisibilityEnum.university &&
        event.creator.university != user.university) {
      return false;
    }

    switch (event.visibility) {
      case VisibilityEnum.everyone:
        return true;
      case VisibilityEnum.university:
        if (user.university == null) return false;
        return event.creator.university == user.university;
      case VisibilityEnum.onlyFriends:
        return context.followeeIds.contains(event.creator.userID);
      case VisibilityEnum.custom:
        final groupId = event.visibilityGroupID;
        if (groupId == null) return false;
        return _groupRepository.isGroupMember(groupId, user.userID);
    }
  }

  @override
  Type get entityType => EventEntity;
}
