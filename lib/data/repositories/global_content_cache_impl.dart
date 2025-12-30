import 'package:bulusalim/core/constants/configs/app_config.dart';
import 'package:bulusalim/core/utils/logging/logging_service.dart';
import 'package:bulusalim/core/utils/types/types.dart';
import 'package:bulusalim/domain/entities/feed/feed_entity.dart';
import 'package:bulusalim/domain/services/global_content_cache.dart';
import 'package:bulusalim/domain/services/in_memory_cache.dart';

class GlobalContentCacheImpl implements GlobalContentCache {
  GlobalContentCacheImpl({
    required LoggingService logger,
  }) : _logger = logger;

  final LoggingService _logger;

  // Senin InMemoryCache sınıfın burada motor görevi görüyor
  final _memoryCache = InMemoryCache<FeedEntity>(
    cacheSizeLimit: AppConfig.feedCacheSizeLimit,
    ttl: AppConfig.feedCacheTTL,
  );

  @override
  void cacheEntity(FeedEntity entity) {
    _memoryCache.set(entity.id, entity);
  }

  @override
  void cacheBatch(List<FeedEntity> entities) {
    for (final entity in entities) {
      _memoryCache.set(entity.id, entity);
    }
  }

  @override
  FeedEntity? getEntity(Identifier id) {
    return _memoryCache.get(id);
  }

  @override
  List<FeedEntity> getEntities(List<Identifier> ids) {
    final results = <FeedEntity>[];
    for (final id in ids) {
      final item = _memoryCache.get(id);
      if (item != null) {
        results.add(item);
      }
    }
    return results;
  }

  @override
  void removeEntity(Identifier id) {
    // NOT: InMemoryCache sınıfına 'remove' metodunu eklemeyi unutma.
    // Şimdilik eklemediysen bu satırı yoruma alabilirsin.
    // _memoryCache.remove(id);
  }

  @override
  void clearAll() {
    _memoryCache.clear();
    _logger.info('GlobalContentCache cleared.');
  }
}
