import 'package:outnest/core/utils/types/enums/emote_enum.dart';
import 'package:outnest/core/utils/types/types.dart';
import 'package:outnest/domain/services/analytics/analytics_constants.dart';

class RemoveEmoteAnalyticsConfig {
  RemoveEmoteAnalyticsConfig({
    required this.postID,
    required this.value,
    required this.isFollower,
    required this.isFollowee,
  });

  final EmoteEnum value;
  final Identifier postID;
  final bool isFollower;
  final bool isFollowee;

  Map<String, Object> toMap() {
    return {
      AnalyticsParams.value: value,
      AnalyticsParams.postID: postID,
      AnalyticsParams.isFollower: isFollower,
      AnalyticsParams.isFollowee: isFollowee,
    };
  }
}
