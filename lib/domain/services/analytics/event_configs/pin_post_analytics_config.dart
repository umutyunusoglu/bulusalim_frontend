import 'package:outnest/core/utils/types/types.dart';
import 'package:outnest/domain/services/analytics/analytics_constants.dart';

class PinPostAnalyticsConfig {
  PinPostAnalyticsConfig({
    required this.postID,
  });

  Map<String, Object> toMap() {
    return {
      AnalyticsParams.postID: postID,
    };
  }

  final Identifier postID;
}
