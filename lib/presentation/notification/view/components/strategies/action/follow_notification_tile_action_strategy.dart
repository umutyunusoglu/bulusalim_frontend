import 'package:outnest/domain/entities/notification/notification_entity.dart';
import 'package:outnest/presentation/notification/view/components/strategies/action/notification_tile_action_config.dart';
import 'package:outnest/presentation/notification/view/components/strategies/action/notification_tile_action_strategy.dart';

class FollowNotificationTileActionStrategy
    implements NotificationTileActionStrategy {
  static final RegExp _safeUserIdPattern = RegExp(r'^[A-Za-z0-9_-]{6,}$');

  @override
  bool canHandle(NotificationEntity notification) {
    final rawType = (notification.rawType ?? '').toLowerCase();
    return rawType.contains('follow');
  }

  @override
  NotificationTileActionConfig build(NotificationEntity notification) {
    final rawType = (notification.rawType ?? '').toLowerCase();

    // Follow-request items should open the inbox page directly.
    if (rawType.contains('follow_request') || rawType.contains('request')) {
      return const NotificationTileActionConfig(
        type: NotificationTileActionType.navigate,
        route: '/follow-requests',
      );
    }

    final actorUserId = notification.actorUserId?.trim();
    if (actorUserId != null && _safeUserIdPattern.hasMatch(actorUserId)) {
      final encodedActorId = Uri.encodeComponent(actorUserId);
      return NotificationTileActionConfig(
        type: NotificationTileActionType.navigate,
        route: '/home/profile/$encodedActorId',
      );
    }

    return const NotificationTileActionConfig(
      type: NotificationTileActionType.navigate,
      route: '/follow-requests',
    );
  }
}
