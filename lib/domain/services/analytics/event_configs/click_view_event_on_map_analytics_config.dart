import 'package:outnest/core/utils/types/types.dart';
import 'package:outnest/domain/services/analytics/analytics_constants.dart';

class ClickViewEventOnMapAnalyticsConfig {
  ClickViewEventOnMapAnalyticsConfig({
    required this.eventID,
  });

  Map<String, Object> toMap() {
    return {
      AnalyticsParams.eventID: eventID,
    };
  }

  final Identifier eventID;
}
