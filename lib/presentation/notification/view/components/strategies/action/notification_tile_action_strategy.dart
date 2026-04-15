import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:outnest/domain/entities/notification/notification_entity.dart';
import 'package:outnest/presentation/notification/view/components/strategies/action/notification_tile_action_config.dart';

abstract class NotificationTileActionStrategy {
  bool canHandle(NotificationEntity notification);

  NotificationTileActionConfig build(
    NotificationEntity notification,
    WidgetRef ref,
  );
}
