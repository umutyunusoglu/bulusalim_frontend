import 'package:outnest/core/utils/types/enums/screen_enum.dart';
import 'package:outnest/core/utils/types/types.dart';
import 'package:outnest/domain/services/analytics/analytics_constants.dart';

class SendJoinRequestToEventAnalyticsConfig {
  SendJoinRequestToEventAnalyticsConfig({
    required this.eventID,
    required this.numberOfParticipants,
    required this.numberOfFollowerParticipants,
    required this.numberOfNonFollowerParticipants,
    required this.numberOfFolloweeParticipants,
    required this.numberOfNonFolloweeParticipants,
    required this.sameUniversityAsCreator,
    required this.numberOfSameUniversityParticipants,
    required this.showOnMap,
    required this.remainingTimeToStart,
    required this.eventStartTime,
    required this.eventVisibility,
    required this.category,
    required this.screen,
  });

  Map<String, Object> toMap() {
    return {
      AnalyticsParams.eventID: eventID,
      AnalyticsParams.numberOfParticipants: numberOfParticipants,
      AnalyticsParams.numberOfFollowerParticipants:
          numberOfFollowerParticipants,
      AnalyticsParams.numberOfNonFollowerParticipants:
          numberOfNonFollowerParticipants,
      AnalyticsParams.numberOfFolloweeParticipants:
          numberOfFolloweeParticipants,
      AnalyticsParams.numberOfNonFolloweeParticipants:
          numberOfNonFolloweeParticipants,
      AnalyticsParams.sameUniversityAsCreator: sameUniversityAsCreator,
      AnalyticsParams.numberOfSameUniversityParticipants:
          numberOfSameUniversityParticipants,
      AnalyticsParams.showOnMap: showOnMap,
      AnalyticsParams.remainingTimeToStart: remainingTimeToStart.inSeconds,
      AnalyticsParams.eventStartTime: eventStartTime.toIso8601String(),
      AnalyticsParams.eventVisibility: eventVisibility,
      AnalyticsParams.category: category,
      AnalyticsParams.screen: screen.toString(),
    };
  }

  final Identifier eventID;
  final int numberOfParticipants;
  final int numberOfFollowerParticipants;
  final int numberOfNonFollowerParticipants;
  final int numberOfFolloweeParticipants;
  final int numberOfNonFolloweeParticipants;
  final bool sameUniversityAsCreator;
  final int numberOfSameUniversityParticipants;
  final bool showOnMap;
  final Duration remainingTimeToStart;
  final DateTime eventStartTime;
  final String eventVisibility;
  final String category;
  final ScreenEnum screen;
}
