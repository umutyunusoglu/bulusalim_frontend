import 'package:outnest/core/utils/types/types.dart';
import 'package:outnest/domain/services/analytics/analytics_constants.dart';

class CreatePostAnalyticsConfig {
  CreatePostAnalyticsConfig({
    required this.eventID,
    required this.postID,
    required this.numberOfPhotosInPost,
    required this.timeElapsedAfterEventStart,
    required this.addToDump,
    required this.showParticipants,
    required this.pinPost,
  });

  Map<String, Object> toMap() {
    return {
      AnalyticsParams.postID: postID,
      AnalyticsParams.numberOfPhotosInPost: numberOfPhotosInPost,
      AnalyticsParams.timeElapsedAfterEventStart:
          timeElapsedAfterEventStart.inSeconds,
      AnalyticsParams.addToDump: addToDump,
      AnalyticsParams.showParticipants: showParticipants,
      AnalyticsParams.pinPost: pinPost,
    };
  }

  final Identifier postID;
  final Identifier eventID;
  final int numberOfPhotosInPost;
  final Duration timeElapsedAfterEventStart;
  final bool addToDump;
  final bool showParticipants;
  final bool pinPost;
}
