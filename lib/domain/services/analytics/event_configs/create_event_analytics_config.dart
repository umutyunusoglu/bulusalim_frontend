import 'package:outnest/core/utils/types/enums/visibility_enum.dart';
import 'package:outnest/domain/services/analytics/analytics_constants.dart';

class CreateEventAnalyticsConfig {
  CreateEventAnalyticsConfig({
    required this.category,
    required this.isLocationSearched,
    required this.hasStartTime,
    required this.visibility,
    required this.showOnMap,
    required this.isNameSuggestionUsed,
  });

  Map<String, Object> toMap() {
    return {
      AnalyticsParams.category: category,
      AnalyticsParams.isLocationSearched: isLocationSearched,
      AnalyticsParams.hasStartTime: hasStartTime,
      AnalyticsParams.eventVisibility: visibility.toString(),
      AnalyticsParams.showOnMap: showOnMap,
      AnalyticsParams.isNameSuggestionUsed: isNameSuggestionUsed,
    };
  }

  final String category;
  final bool isLocationSearched;
  final bool hasStartTime;
  final VisibilityEnum visibility;
  final bool showOnMap;
  final bool isNameSuggestionUsed;
}
