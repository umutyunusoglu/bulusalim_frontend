import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:outnest/core/utils/types/enums/visibility_enum.dart';
import 'package:outnest/domain/entities/feed/event/event_entity.dart';
import 'package:outnest/domain/entities/user/compact_user_entity.dart';
import 'package:outnest/domain/entities/user/user_entity.dart';

/// Paginated result wrapper for user searches.
///
/// Contains the current page of [users], a Firestore [lastDoc] cursor
/// for fetching the next page, and a [hasMore] flag indicating whether
/// additional pages are available.
class UserSearchResult {
  final List<CompactUserEntity> users;

  /// The last [DocumentSnapshot] in this page, used as a cursor
  /// for `startAfterDocument` in subsequent queries.
  final DocumentSnapshot? lastDoc;

  /// `true` when at least one more page of results exists in Firestore.
  final bool hasMore;

  const UserSearchResult({
    required this.users,
    this.lastDoc,
    this.hasMore = false,
  });
}

/// Paginated result wrapper for event searches.
///
/// Same pagination semantics as [UserSearchResult].
class EventSearchResult {
  final List<EventEntity> events;
  final DocumentSnapshot? lastDoc;
  final bool hasMore;

  const EventSearchResult({
    required this.events,
    this.lastDoc,
    this.hasMore = false,
  });
}

/// Contract for search operations across users and events.
///
/// Implementations are expected to:
/// - Return results in pages of a fixed size.
/// - Prioritise the caller's [followers] list before falling back to Firestore.
/// - Support cursor-based pagination via [startAfter].
/// - Filter events by the current user's visibility permissions.
abstract class SearchRepository {
  /// Searches for users matching [query].
  ///
  /// **Priority order (first page only):**
  /// 1. Users within [followers] whose username starts with [query].
  /// 2. Remaining slots filled from the `public_users` Firestore collection.
  ///
  /// On subsequent pages (when [startAfter] is provided), only Firestore
  /// results are returned.
  ///
  /// [excludeIds] – user IDs already displayed; these are skipped in
  /// Firestore results to avoid duplicates.
  Future<UserSearchResult> searchUsers({
    required String query,
    required List<CompactUserEntity> followers,
    DocumentSnapshot? startAfter,
    Set<String>? excludeIds,
  });

  /// Searches for events whose `searchName` starts with [query].
  ///
  /// Results are ordered alphabetically and paginated via [startAfter].
  ///
  /// Only events visible to the current user are returned. Visibility
  /// is determined by [currentUser], [followeeIds], and the event's
  /// [VisibilityEnum] setting:
  /// - **everyone** – always visible.
  /// - **university** – visible only if the user shares the creator's university.
  /// - **onlyFriends** – visible only if the user follows the creator.
  /// - **custom** – visible only if the user is a member of the event's visibility group.
  Future<EventSearchResult> searchEvents({
    required String query,
    required UserEntity currentUser,
    DocumentSnapshot? startAfter,
  });
}
