import 'package:outnest/domain/entities/notification/notification_entity.dart';
import 'package:outnest/presentation/notification/view/components/strategies/action/notification_tile_action_config.dart';
import 'package:outnest/presentation/notification/view/components/strategies/action/notification_tile_action_strategy.dart';

class DefaultNotificationTileActionStrategy
    implements NotificationTileActionStrategy {
  @override
  bool canHandle(NotificationEntity notification) => true;

  @override
  NotificationTileActionConfig build(NotificationEntity notification) {
    return const NotificationTileActionConfig(
      type: NotificationTileActionType.none,
      infoMessage: 'Bu bildirim için henüz bir aksiyon tanımlanmadı.',
    );
  }
}
