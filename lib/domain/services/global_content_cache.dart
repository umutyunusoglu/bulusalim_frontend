import 'package:outnest/core/utils/types/types.dart';
import 'package:outnest/domain/entities/feed/feed_entity.dart';

abstract class GlobalContentCache {
  /// Tek bir entity'yi cache'e ekler veya günceller.
  void cacheEntity(FeedEntity entity);

  /// Toplu entity ekler.
  void cacheBatch(List<FeedEntity> entities);

  /// ID'ye göre entity getirir. Bulamazsa null döner.
  FeedEntity? getEntity(Identifier id);

  /// ID listesine göre entity'leri getirir.
  List<FeedEntity> getEntities(List<Identifier> ids);

  /// Belirli bir ID'yi cache'ten siler.
  void removeEntity(Identifier id);

  /// Tüm cache'i temizler.
  void clearAll();
}
