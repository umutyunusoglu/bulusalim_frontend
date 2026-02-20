import 'package:outnest/core/utils/types/types.dart';
import 'package:outnest/domain/services/analytics/analytics_constants.dart';

class UpdateEventLockedStatusAnalyticsConfig {
  UpdateEventLockedStatusAnalyticsConfig({
    required this.eventID,
    required this.value,
  });

  Map<String, Object> toMap() {
    return {
      AnalyticsParams.eventID: eventID,
      AnalyticsParams.value: value,
    };
  }

  final Identifier eventID;
  final bool value;
}
