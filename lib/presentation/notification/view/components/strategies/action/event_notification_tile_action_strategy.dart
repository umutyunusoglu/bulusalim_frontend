import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:outnest/application/app_state/current_user_data_providers/current_user_event_providers.dart';
import 'package:outnest/core/utils/types/enums/event_status_enum.dart';
import 'package:outnest/domain/entities/notification/notification_entity.dart';
import 'package:outnest/presentation/notification/view/components/strategies/action/notification_tile_action_config.dart';
import 'package:outnest/presentation/notification/view/components/strategies/action/notification_tile_action_strategy.dart';
import 'package:outnest/presentation/shared/event_card/controllers/event_join_controller.dart';

class EventNotificationTileActionStrategy
    implements NotificationTileActionStrategy {
  @override
  bool canHandle(NotificationEntity notification) {
    return notification.eventId != null && notification.eventId!.isNotEmpty;
  }

  @override
  NotificationTileActionConfig build(
    NotificationEntity notification,
    WidgetRef ref,
  ) {
    final myevents = ref.watch(activeEventsProvider);

    final isAcceptedNotification = myevents.any(
      (event) => event.id == notification.eventId,
    );

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
