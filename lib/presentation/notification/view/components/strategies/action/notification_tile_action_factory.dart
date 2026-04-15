import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:outnest/domain/entities/notification/notification_entity.dart';
import 'package:outnest/presentation/notification/view/components/strategies/action/default_notification_tile_action_strategy.dart';
import 'package:outnest/presentation/notification/view/components/strategies/action/event_notification_tile_action_strategy.dart';
import 'package:outnest/presentation/notification/view/components/strategies/action/follow_notification_tile_action_strategy.dart';
import 'package:outnest/presentation/notification/view/components/strategies/action/notification_tile_action_config.dart';
import 'package:outnest/presentation/notification/view/components/strategies/action/notification_tile_action_strategy.dart';

class NotificationTileActionFactory {
  NotificationTileActionFactory({
    List<NotificationTileActionStrategy>? strategies,
    NotificationTileActionStrategy? fallback,
  }) : _strategies =
           strategies ??
           [
             FollowNotificationTileActionStrategy(),
             EventNotificationTileActionStrategy(),
           ],
       _fallback = fallback ?? DefaultNotificationTileActionStrategy();

  final List<NotificationTileActionStrategy> _strategies;
  final NotificationTileActionStrategy _fallback;

  NotificationTileActionConfig build(
    NotificationEntity notification,
    WidgetRef ref,
  ) {
    for (final strategy in _strategies) {
      if (strategy.canHandle(notification)) {
        return strategy.build(notification, ref);
      }
    }

    return _fallback.build(notification, ref);
  }
}
