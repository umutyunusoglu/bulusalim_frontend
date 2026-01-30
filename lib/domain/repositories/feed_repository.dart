import 'package:outnest/core/utils/types/enums/feed_type.dart';
import 'package:outnest/domain/entities/feed/feed_entity.dart';

abstract class FeedRepository {
  Future<List<FeedEntity>> fetchAllFeedItems();

  Future<List<FeedEntity>> fetchNextFeedBatch(
    FeedEntity? referenceFeedItem,
  );
  Future<List<FeedEntity>> fetchPreviousFeedBatch(
    FeedEntity referenceFeedItem,
  );

  // Initializes cache or preloads data to improve performance
  Future<void> warmup();

  //FOR V2
  Stream<List<FeedEntity>> get feedStream;

  Future<void> switchFeedType(FeedType feedType);

  // Pagination tetikleyici. UI listenin sonuna gelince bunu çağırır.
  Future<void> loadMore();

  // Sayfayı yenileme. En başa döner.
  Future<void> refresh();

  // Event detaylarının (Katılımcı sayısı vb.) canlı kalması için yardımcı metod.
  Stream<FeedEntity> getLiveEventStream(String eventId);

  void dispose();
}
