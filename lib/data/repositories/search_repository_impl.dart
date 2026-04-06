import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:outnest/application/get_it_service_locators/get_it_init.dart';
import 'package:outnest/core/utils/types/enums/visibility_enum.dart';
import 'package:outnest/data/models/event/event_model.dart';
import 'package:outnest/domain/entities/feed/event/event_entity.dart';
import 'package:outnest/domain/entities/user/compact_user_entity.dart';
import 'package:outnest/domain/entities/user/user_entity.dart';
import 'package:outnest/domain/repositories/group_repository.dart';
import 'package:outnest/domain/repositories/search_repository.dart';

class SearchRepositoryImpl implements SearchRepository {
  final FirebaseFirestore _firestore;
  static const int pageSize = 10;

  /// Over-fetch multiplier – we pull extra docs per round to compensate
  /// for events that will be filtered out by visibility checks.
  static const int _fetchMultiplier = 2;

  SearchRepositoryImpl({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  @override
  Future<UserSearchResult> searchUsers({
    required String query,
    required List<CompactUserEntity> followers,
    DocumentSnapshot? startAfter,
    Set<String>? excludeIds,
  }) async {
    final searchTerm = query.trim().toLowerCase();
    if (searchTerm.isEmpty) {
      return const UserSearchResult(users: []);
    }

    final alreadyShown = excludeIds ?? <String>{};
    final results = <CompactUserEntity>[];

    if (startAfter == null) {
      final matches = followers
          .where(
            (f) =>
                f.username.toLowerCase().startsWith(searchTerm) &&
                !alreadyShown.contains(f.userID),
          )
          .take(pageSize)
          .toList();

      results.addAll(matches);
      alreadyShown.addAll(matches.map((u) => u.userID));
    }

    final remaining = pageSize - results.length;
    DocumentSnapshot? lastDoc;
    bool hasMore = false;

    if (remaining > 0) {
      var firestoreQuery = _firestore
          .collection('public_users')
          .orderBy('username')
          .startAt([searchTerm])
          .endAt(['$searchTerm\uf8ff'])
          .limit(remaining + 1);

      if (startAfter != null) {
        firestoreQuery = firestoreQuery.startAfterDocument(startAfter);
      }

      final snapshot = await firestoreQuery.get();
      final docs = snapshot.docs
          .where((doc) => !alreadyShown.contains(doc.id))
          .toList();

      hasMore = docs.length > remaining;
      final pageDocs = hasMore ? docs.sublist(0, remaining) : docs;

      for (final doc in pageDocs) {
        results.add(
          CompactUserEntity.fromMap({
            ...doc.data(),
            'userID': doc.id,
          }),
        );
      }

      lastDoc = pageDocs.isNotEmpty ? pageDocs.last : startAfter;
    }

    return UserSearchResult(
      users: results,
      lastDoc: lastDoc,
      hasMore: hasMore,
    );
  }

  @override
  Future<EventSearchResult> searchEvents({
    required String query,
    required UserEntity currentUser,
    DocumentSnapshot? startAfter,
  }) async {
    final searchTerm = query.trim().toLowerCase();
    if (searchTerm.isEmpty) {
      return const EventSearchResult(events: []);
    }

    final visible = <EventEntity>[];
    DocumentSnapshot? cursor = startAfter;
    bool exhausted = false;

    // Keep fetching until we fill a page or run out of docs.
    while (visible.length < pageSize && !exhausted) {
      final batchSize = (pageSize - visible.length) * _fetchMultiplier;

      var eventQuery = _firestore
          .collection('events')
          .orderBy('searchName')
          .startAt([searchTerm])
          .endAt(['$searchTerm\uf8ff'])
          .limit(batchSize);

      if (cursor != null) {
        eventQuery = eventQuery.startAfterDocument(cursor);
      }

      final snapshot = await eventQuery.get();
      if (snapshot.docs.isEmpty) {
        exhausted = true;
        break;
      }

      cursor = snapshot.docs.last;

      if (snapshot.docs.length < batchSize) {
        exhausted = true;
      }

      for (final doc in snapshot.docs) {
        if (visible.length >= pageSize) break;

        final event = EventModel.fromFirestore(
          {...doc.data(), 'eventID': doc.id},
        ).toEntity();

        final allowed = await _isVisible(
          event: event,
          currentUser: currentUser,
        );

        if (allowed) {
          visible.add(event);
        }
      }
    }

    return EventSearchResult(
      events: visible,
      lastDoc: cursor,
      hasMore: !exhausted,
    );
  }

  /// Returns `true` if [currentUser] is allowed to see [event]
  /// based on its [VisibilityEnum] setting.
  Future<bool> _isVisible({
    required EventEntity event,
    required UserEntity currentUser,
  }) async {
    switch (event.visibility) {
      case VisibilityEnum.everyone:
        return true;
      case VisibilityEnum.university:
        if (currentUser.university == null) return false;
        return event.creator.university == currentUser.university;
      case VisibilityEnum.onlyFriends:
        return currentUser.followeeIds?.contains(event.creator.userID) ?? false;
      case VisibilityEnum.custom:
        final groupId = event.visibilityGroupID;
        if (groupId == null) return false;
        return await getIt<GroupRepository>().isGroupMember(
          groupId,
          currentUser.userID,
        );
    }
  }
}
