import 'package:outnest/domain/entities/feed/feed_entity.dart';

abstract class FeedRepository {
  Stream<List<FeedEntity>> get feedStream;

  Future<void> loadMore();
  Future<void> refresh();
  Future<void> warmup();

  Stream<T> getLiveStream<T extends FeedEntity>(String id);

  /// Removes an item from the local feed stream by id without
  /// touching Firestore. Used after a soft-delete so the UI reacts
  /// instantly — the next refresh will naturally exclude the
  /// deleted item server-side too.
  void removeItem(String id);

  void dispose();
}
