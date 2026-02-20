import 'package:outnest/domain/services/analytics/analytics_constants.dart';

class ClickHideSavedEventsAnalyticsConfig {
  ClickHideSavedEventsAnalyticsConfig({
    required this.value,
  });

  Map<String, Object> toMap() {
    return {
      AnalyticsParams.value: value,
    };
  }

  final bool value;
}
