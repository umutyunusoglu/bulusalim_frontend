import 'package:bulusalim/domain/entities/feed/feed_entity.dart';

abstract class FeedRepository {
  Future<List<FeedEntity>> fetchNextFeedBatch(
    FeedEntity? referenceFeedItem,
  );
  Future<List<FeedEntity>> fetchPreviousFeedBatch(
    FeedEntity referenceFeedItem,
  );

  // Initializes cache or preloads data to improve performance
  Future<void> warmup();
}
