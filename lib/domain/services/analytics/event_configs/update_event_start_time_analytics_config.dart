import 'package:outnest/core/utils/types/types.dart';
import 'package:outnest/domain/services/analytics/analytics_constants.dart';

class UpdateEventStartTimeAnalyticsConfig {
  UpdateEventStartTimeAnalyticsConfig({
    required this.eventID,
    required this.value,
    required this.previousValue,
  });

  Map<String, Object> toMap() {
    return {
      AnalyticsParams.eventID: eventID,
      AnalyticsParams.value: value.toIso8601String(),
      AnalyticsParams.previousValue: previousValue.toIso8601String(),
    };
  }

  final Identifier eventID;
  final DateTime value;
  final DateTime previousValue;
}
