import 'package:outnest/core/utils/types/enums/visibility_enum.dart';
import 'package:outnest/core/utils/types/types.dart';
import 'package:outnest/domain/services/analytics/analytics_constants.dart';

class UpdateEventVisibilityAnalyticsConfig {
  UpdateEventVisibilityAnalyticsConfig({
    required this.eventID,
    required this.value,
    required this.previousValue,
  });

  Map<String, Object> toMap() {
    return {
      AnalyticsParams.eventID: eventID,
      AnalyticsParams.value: value.toString(),
      AnalyticsParams.previousValue: previousValue.toString(),
    };
  }

  final Identifier eventID;
  final VisibilityEnum value;
  final VisibilityEnum previousValue;
}
