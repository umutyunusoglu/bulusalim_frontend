import 'package:outnest/domain/entities/notification/notification_entity.dart';
import 'package:outnest/presentation/notification/view/components/strategies/visual/badge_notification_tile_strategy.dart';
import 'package:outnest/presentation/notification/view/components/strategies/visual/calendar_notification_tile_strategy.dart';
import 'package:outnest/presentation/notification/view/components/strategies/visual/cancel_notification_tile_strategy.dart';
import 'package:outnest/presentation/notification/view/components/strategies/visual/default_notification_tile_strategy.dart';
import 'package:outnest/presentation/notification/view/components/strategies/visual/invite_notification_tile_strategy.dart';
import 'package:outnest/presentation/notification/view/components/strategies/visual/join_notification_tile_strategy.dart';
import 'package:outnest/presentation/notification/view/components/strategies/visual/notification_tile_strategy.dart';
import 'package:outnest/presentation/notification/view/components/strategies/visual/notification_tile_visual_config.dart';
import 'package:outnest/presentation/notification/view/components/strategies/visual/warning_notification_tile_strategy.dart';

class NotificationTileFactory {
  NotificationTileFactory({
    List<NotificationTileStrategy>? strategies,
    NotificationTileStrategy? fallback,
  }) : _strategies =
           strategies ??
           [
             WarningNotificationTileStrategy(),
             BadgeNotificationTileStrategy(),
             CalendarNotificationTileStrategy(),
             InviteNotificationTileStrategy(),
             JoinNotificationTileStrategy(),
             CancelNotificationTileStrategy(),
           ],
       _fallback = fallback ?? DefaultNotificationTileStrategy();

  final List<NotificationTileStrategy> _strategies;
  final NotificationTileStrategy _fallback;

  NotificationTileVisualConfig build(NotificationEntity notification) {
    for (final strategy in _strategies) {
      if (strategy.canHandle(notification)) {
        return strategy.build(notification);
      }
    }

    return _fallback.build(notification);
  }
}
