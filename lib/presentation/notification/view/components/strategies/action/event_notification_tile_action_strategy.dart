import 'package:outnest/domain/entities/notification/notification_entity.dart';
import 'package:outnest/presentation/notification/view/components/strategies/action/notification_tile_action_config.dart';
import 'package:outnest/presentation/notification/view/components/strategies/action/notification_tile_action_strategy.dart';

class EventNotificationTileActionStrategy
    implements NotificationTileActionStrategy {
  @override
  bool canHandle(NotificationEntity notification) {
    return notification.eventId != null && notification.eventId!.isNotEmpty;
  }

  @override
  NotificationTileActionConfig build(NotificationEntity notification) {
    final rawType = (notification.rawType ?? '').toLowerCase();
    final isAcceptedNotification =
        notification.type == NotificationType.join ||
        rawType == 'join' ||
        rawType.contains('accept');

    if (isAcceptedNotification) {
      return NotificationTileActionConfig(
        type: NotificationTileActionType.navigate,
        route: '/chat/room/${notification.eventId}',
      );
    }

    return NotificationTileActionConfig(
      type: NotificationTileActionType.navigate,
      route: '/share/event/${notification.eventId}',
    );
  }
}
