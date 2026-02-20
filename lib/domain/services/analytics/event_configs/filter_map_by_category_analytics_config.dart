import 'package:outnest/domain/services/analytics/analytics_constants.dart';

class FilterMapByCategoryAnalyticsConfig {
  FilterMapByCategoryAnalyticsConfig({
    required this.category,
  });

  Map<String, Object> toMap() {
    return {
      AnalyticsParams.value: category,
    };
  }

  final String category;
}
