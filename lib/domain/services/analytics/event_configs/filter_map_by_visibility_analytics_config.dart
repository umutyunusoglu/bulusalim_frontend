import 'package:outnest/core/utils/types/enums/visibility_enum.dart';
import 'package:outnest/domain/services/analytics/analytics_constants.dart';

class FilterMapByVisibilityAnalyticsConfig {
  FilterMapByVisibilityAnalyticsConfig({
    required this.visibility,
  });

  Map<String, Object> toMap() {
    return {
      AnalyticsParams.value: visibility,
    };
  }

  final VisibilityEnum visibility;
}
