import 'package:outnest/core/utils/types/types.dart';
import 'package:outnest/domain/services/analytics/analytics_constants.dart';

class ForceStartEventAnalyticsConfig {
  ForceStartEventAnalyticsConfig({
    required this.eventID,
    required this.timeToEventStart,
  });

  Map<String, Object> toMap() {
    return {
      AnalyticsParams.eventID: eventID,
      AnalyticsParams.remainingTimeToStart: timeToEventStart.inSeconds,
    };
  }

  final Identifier eventID;
  final Duration timeToEventStart;
}
