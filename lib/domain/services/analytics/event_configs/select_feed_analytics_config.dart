import 'package:outnest/core/utils/types/enums/feed_type.dart';
import 'package:outnest/domain/services/analytics/analytics_constants.dart';

class SelectFeedAnalyticsConfig {
  SelectFeedAnalyticsConfig({
    required this.value,
    required this.previousValue,
  });

  final FeedType value;
  final FeedType previousValue;

  Map<String, Object> toMap() {
    return {
      AnalyticsParams.value: value,
      AnalyticsParams.previousValue: previousValue,
    };
  }
}
