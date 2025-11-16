import 'package:bulusalim/core/constants/Configs/app_config.dart';
import 'package:bulusalim/domain/feed/feed_entity.dart';
import 'package:bulusalim/domain/repositories/feed_repository.dart';

class FeedRepositoryImpl implements FeedRepository {
  final batchSize = AppConfig.feedBatchSize;

  @override
  Future<List<FeedEntity>> fetchNextFeedBatch(
    FeedEntity? referenceFeedItem,
    int batchSize,
  ) {
    // TODO: implement fetchNextFeedBatch
    throw UnimplementedError();
  }

  @override
  Future<List<FeedEntity>> fetchPreviousFeedBatch(
    FeedEntity referenceFeedItem,
    int batchSize,
  ) {
    // TODO: implement fetchPreviousFeedBatch
    throw UnimplementedError();
  }
}
