import 'package:flutter/material.dart';
import 'package:outnest/domain/entities/notification/notification_entity.dart';
import 'package:outnest/presentation/notification/view/components/strategies/visual/notification_tile_strategy.dart';
import 'package:outnest/presentation/notification/view/components/strategies/visual/notification_tile_visual_config.dart';

class CalendarNotificationTileStrategy implements NotificationTileStrategy {
  @override
  bool canHandle(NotificationEntity notification) {
    return notification.type == NotificationType.updateTime ||
        notification.type == NotificationType.updateLocation ||
        notification.type == NotificationType.startingSoon ||
        notification.type == NotificationType.earlyStart;
  }

  @override
  NotificationTileVisualConfig build(NotificationEntity notification) {
    return const NotificationTileVisualConfig(
      badgeIcon: Icons.calendar_today_rounded,
      badgeColor: Color(0xFFFF9500),
      badgeIconSizeSp: 10,
    );
  }
}
