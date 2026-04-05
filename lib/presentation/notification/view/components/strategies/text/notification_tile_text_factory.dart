import 'package:outnest/domain/entities/notification/notification_entity.dart';
import 'package:outnest/presentation/notification/view/components/strategies/text/default_notification_tile_text_strategy.dart';
import 'package:outnest/presentation/notification/view/components/strategies/text/invite_notification_tile_text_strategy.dart';
import 'package:outnest/presentation/notification/view/components/strategies/text/notification_tile_text_config.dart';
import 'package:outnest/presentation/notification/view/components/strategies/text/notification_tile_text_strategy.dart';

// This factory class is responsible for building the text configuration for a notification tile based on the provided notification entity. It uses a list of strategies to determine how to build the text configuration for different types of notifications, and falls back to a default strategy if no specific strategy can handle the notification.
class NotificationTileTextFactory {
  NotificationTileTextFactory({
    List<NotificationTileTextStrategy>? strategies,
    NotificationTileTextStrategy? fallback,
  }) : _strategies = strategies ?? [InviteNotificationTileTextStrategy()],
       _fallback = fallback ?? DefaultNotificationTileTextStrategy();

  final List<NotificationTileTextStrategy> _strategies;
  final NotificationTileTextStrategy _fallback;

  NotificationTileTextConfig build(NotificationEntity notification) {
    for (final strategy in _strategies) {
      if (strategy.canHandle(notification)) {
        return strategy.build(notification);
      }
    }

    return _fallback.build(notification);
  }
}
