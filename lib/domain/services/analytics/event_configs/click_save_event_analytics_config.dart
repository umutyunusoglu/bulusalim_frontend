import 'package:outnest/core/utils/types/enums/screen_enum.dart';
import 'package:outnest/core/utils/types/types.dart';
import 'package:outnest/domain/services/analytics/analytics_constants.dart';

class ClickSaveEventAnalyticsConfig {
  ClickSaveEventAnalyticsConfig({
    required this.eventID,
    required this.value,
    required this.screen,
  });

  Map<String, Object> toMap() {
    return {
      AnalyticsParams.eventID: eventID,
      AnalyticsParams.value: value,
      AnalyticsParams.screen: screen.toString(),
    };
  }

  final Identifier eventID;
  final bool value;
  final ScreenEnum screen;
}
