import 'package:flutter/material.dart';
import 'package:outnest/domain/entities/notification/notification_entity.dart';
import 'package:outnest/presentation/notification/view/components/strategies/visual/notification_tile_strategy.dart';
import 'package:outnest/presentation/notification/view/components/strategies/visual/notification_tile_visual_config.dart';

class CancelNotificationTileStrategy implements NotificationTileStrategy {
  @override
  bool canHandle(NotificationEntity notification) {
    return notification.type == NotificationType.cancel;
  }

  @override
  NotificationTileVisualConfig build(NotificationEntity notification) {
    return const NotificationTileVisualConfig(
      badgeIcon: Icons.close_rounded,
      badgeColor: Color(0xFFFF3B30),
    );
  }
}
