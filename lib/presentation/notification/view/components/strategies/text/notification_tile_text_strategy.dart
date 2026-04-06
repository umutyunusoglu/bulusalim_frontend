import 'package:outnest/domain/entities/notification/notification_entity.dart';
import 'package:outnest/presentation/notification/view/components/strategies/text/notification_tile_text_config.dart';

// This abstract class defines the interface for strategies that build the text configuration for a notification tile based on a given notification entity. Each strategy can determine if it can handle a specific type of notification and then build the appropriate text configuration for that notification.
abstract class NotificationTileTextStrategy {
  bool canHandle(NotificationEntity notification);

  NotificationTileTextConfig build(NotificationEntity notification);
}
