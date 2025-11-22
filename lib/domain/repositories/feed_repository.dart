import 'package:bulusalim/domain/entities/feed/feed_entity.dart';

abstract class FeedRepository {
  Future<List<FeedEntity>> fetchNextFeedBatch(
    FeedEntity? referenceFeedItem,
    int batchSize,
  );
  Future<List<FeedEntity>> fetchPreviousFeedBatch(
    FeedEntity referenceFeedItem,
    int batchSize,
  );
}
