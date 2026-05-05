// domain/feed/sources/feed_source.dart

import 'package:outnest/core/utils/types/enums/feed_type.dart';
import 'package:outnest/domain/entities/feed/feed_entity.dart';
import 'package:outnest/domain/entities/user/user_entity.dart';

/// Context required by a feed source to perform a fetch.
///
/// The repository builds this once per [FeedSource.fetch] call and
/// passes it to every source so they share a consistent view of the
/// current user, social graph and feed mode.
class FeedFetchContext {
  const FeedFetchContext({
    required this.user,
    required this.followeeIds,
    required this.blockedIds,
    required this.feedType,
  });

  final UserEntity user;
  final List<String> followeeIds;
  final Set<String> blockedIds;
  final FeedType feedType;
}

/// A single content source that contributes items to the feed
/// (e.g. posts, events, and future entity types).
///
/// Each source is fully self-contained and owns:
///   - its Firestore query construction,
///   - its pagination cursor,
///   - its filtering and visibility rules,
///   - any enrichment required before the entity reaches the UI.
///
/// The repository simply orchestrates sources; it never reaches into
/// their internals. To add a new content type to the feed, implement
/// this interface and register the source — no repository changes
/// should be needed.
abstract class FeedSource {
  /// Fetches the next batch for this source.
  ///
  /// The returned entities are already filtered and enriched, ready
  /// to be displayed by the UI.
  Future<List<FeedEntity>> fetch({
    required FeedFetchContext context,
    required int limit,
  });

  /// Resets the pagination cursor.
  ///
  /// Called by the repository on refresh or when the feed type
  /// changes, so the next [fetch] starts from the most recent items.
  void reset();
}

/// Optional capability for sources whose entities require live updates
/// after they appear in the feed (e.g. an event whose participant
/// count changes in real time).
///
/// Sources should mix this in only when liveness is critical for the
/// entity type. The repository dispatches by [entityType], so each
/// supported entity type may have at most one [LiveFeedSource].
abstract class LiveFeedSource<T extends FeedEntity> {
  /// The concrete entity type this source emits live updates for.
  /// Used by the repository to dispatch `getLiveStream<T>` calls.
  Type get entityType => T;

  /// Returns a stream that emits updated versions of the entity with
  /// the given id. The stream should complete or error if the entity
  /// no longer exists.
  Stream<T> liveStream(String id);
}
