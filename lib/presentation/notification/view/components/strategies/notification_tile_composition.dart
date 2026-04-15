import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:outnest/domain/entities/notification/notification_entity.dart';
import 'package:outnest/presentation/notification/view/components/strategies/action/notification_tile_action_config.dart';
import 'package:outnest/presentation/notification/view/components/strategies/action/notification_tile_action_factory.dart';
import 'package:outnest/presentation/notification/view/components/strategies/action/notification_tile_action_strategy.dart';
import 'package:outnest/presentation/notification/view/components/strategies/text/notification_tile_text_config.dart';
import 'package:outnest/presentation/notification/view/components/strategies/text/notification_tile_text_factory.dart';
import 'package:outnest/presentation/notification/view/components/strategies/text/notification_tile_text_strategy.dart';
import 'package:outnest/presentation/notification/view/components/strategies/visual/notification_tile_factory.dart';
import 'package:outnest/presentation/notification/view/components/strategies/visual/notification_tile_strategy.dart';
import 'package:outnest/presentation/notification/view/components/strategies/visual/notification_tile_visual_config.dart';

class NotificationTileComposition {
  NotificationTileComposition({
    NotificationTileFactory? visualFactory,
    NotificationTileTextFactory? textFactory,
    this.actionFactory,
  }) : _visualFactory = visualFactory ?? NotificationTileFactory(),
       _textFactory = textFactory ?? NotificationTileTextFactory();

  NotificationTileComposition.fromStrategies({
    required List<NotificationTileStrategy> visualStrategies,
    NotificationTileStrategy? visualFallback,
    required List<NotificationTileTextStrategy> textStrategies,
    NotificationTileTextStrategy? textFallback,
    List<NotificationTileActionStrategy>? actionStrategies,
    NotificationTileActionStrategy? actionFallback,
  }) : _visualFactory = NotificationTileFactory(
         strategies: visualStrategies,
         fallback: visualFallback,
       ),
       _textFactory = NotificationTileTextFactory(
         strategies: textStrategies,
         fallback: textFallback,
       ),
       actionFactory = actionStrategies == null
           ? null
           : NotificationTileActionFactory(
               strategies: actionStrategies,
               fallback: actionFallback,
             );

  final NotificationTileFactory _visualFactory;
  final NotificationTileTextFactory _textFactory;

  // Optional by design. Some contexts only need visual/text composition.
  final NotificationTileActionFactory? actionFactory;

  NotificationTileVisualConfig buildVisual(NotificationEntity notification) {
    return _visualFactory.build(notification);
  }

  NotificationTileTextConfig buildText(NotificationEntity notification) {
    return _textFactory.build(notification);
  }

  NotificationTileActionConfig? buildAction(
    NotificationEntity notification,
    WidgetRef ref,
  ) {
    return actionFactory?.build(notification, ref);
  }
}
