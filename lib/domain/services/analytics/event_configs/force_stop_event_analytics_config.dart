import 'package:outnest/core/utils/types/types.dart';
import 'package:outnest/domain/services/analytics/analytics_constants.dart';

class ForceStopEventAnalyticsConfig {
  ForceStopEventAnalyticsConfig({
    required this.eventID,
    required this.timeToEventToStop,
  });

  Map<String, Object> toMap() {
    return {
      AnalyticsParams.eventID: eventID,
      AnalyticsParams.remainingTimeToStop: timeToEventToStop.inSeconds,
    };
  }

  final Identifier eventID;
  final Duration timeToEventToStop;
}
