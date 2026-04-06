import 'package:outnest/domain/entities/notification/notification_entity.dart';
import 'package:outnest/presentation/notification/view/components/strategies/visual/notification_tile_strategy.dart';
import 'package:outnest/presentation/notification/view/components/strategies/visual/notification_tile_visual_config.dart';

class BadgeNotificationTileStrategy implements NotificationTileStrategy {
  @override
  bool canHandle(NotificationEntity notification) {
    return notification.type == NotificationType.badgeWin ||
        notification.type == NotificationType.badgeProgress;
  }

  @override
  NotificationTileVisualConfig build(NotificationEntity notification) {
    return const NotificationTileVisualConfig(
      hideBadge: true,
      useBadgeAvatar: true,
      badgeAvatarLabel: 'rozet',
    );
  }
}
