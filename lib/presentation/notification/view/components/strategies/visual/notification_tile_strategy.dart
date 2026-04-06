import 'package:outnest/domain/entities/notification/notification_entity.dart';
import 'package:outnest/presentation/notification/view/components/strategies/visual/notification_tile_visual_config.dart';

abstract class NotificationTileStrategy {
  bool canHandle(NotificationEntity notification);

  NotificationTileVisualConfig build(NotificationEntity notification);
}
