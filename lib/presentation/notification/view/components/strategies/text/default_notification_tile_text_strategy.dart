import 'package:outnest/domain/entities/notification/notification_entity.dart';
import 'package:outnest/presentation/notification/view/components/strategies/text/notification_tile_text_config.dart';
import 'package:outnest/presentation/notification/view/components/strategies/text/notification_tile_text_strategy.dart';

class DefaultNotificationTileTextStrategy
    implements NotificationTileTextStrategy {
  @override
  bool canHandle(NotificationEntity notification) => true;

  @override
  NotificationTileTextConfig build(NotificationEntity notification) {
    return NotificationTileTextConfig(
      title: notification.title,
      message: notification.message,
      actionText: notification.actionText,
    );
  }
}
