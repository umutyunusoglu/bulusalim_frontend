import 'package:outnest/core/utils/types/geolocation/geolocation.dart';
import 'package:outnest/core/utils/types/types.dart';
import 'package:outnest/domain/services/analytics/analytics_constants.dart';

class UpdateEventLocationAnalyticsConfig {
  UpdateEventLocationAnalyticsConfig({
    required this.eventID,
    required this.value,
    required this.previousValue,
  });

  Map<String, Object> toMap() {
    return {
      AnalyticsParams.eventID: eventID,
      AnalyticsParams.value: value,
      AnalyticsParams.previousValue: previousValue,
    };
  }

  final Identifier eventID;
  final String value;
  final String previousValue;
}
