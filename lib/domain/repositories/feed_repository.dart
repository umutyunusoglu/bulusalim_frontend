import 'package:outnest/domain/entities/feed/feed_entity.dart';

abstract class FeedRepository {
  Stream<List<FeedEntity>> get feedStream;

  Future<void> loadMore();
  Future<void> refresh();
  Future<void> warmup();

  Stream<T> getLiveStream<T extends FeedEntity>(String id);

  void dispose();
}
