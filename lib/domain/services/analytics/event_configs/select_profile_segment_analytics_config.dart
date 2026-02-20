import 'package:outnest/core/utils/types/enums/profile_segment_enum.dart';
import 'package:outnest/domain/services/analytics/analytics_constants.dart';

class SelectProfileSegmentAnalyticsConfig {
  SelectProfileSegmentAnalyticsConfig({
    required this.segment,
  });

  Map<String, Object> toMap() {
    return {
      AnalyticsParams.value: segment.toString(),
    };
  }

  final ProfileSegmentEnum segment;
}
