import 'package:outnest/domain/services/analytics/analytics_constants.dart';

class SelectHobbiesAnalyticsConfig {
  SelectHobbiesAnalyticsConfig({
    required this.value,
    required this.previousValue,
  });

  final List<String> value;
  final List<String> previousValue;

  Map<String, Object> toMap() {
    return {
      AnalyticsParams.value: value,
      AnalyticsParams.previousValue: previousValue,
    };
  }
}
