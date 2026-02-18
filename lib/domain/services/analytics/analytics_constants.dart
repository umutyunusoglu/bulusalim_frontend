import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:outnest/core/utils/types/enums/emote_enum.dart';
import 'package:outnest/core/utils/types/enums/feed_type.dart';
import 'package:outnest/core/utils/types/enums/gender_enum.dart';
import 'package:outnest/core/utils/types/types.dart';

class AnalyticsEvents {
  static const String universityVerified = 'university_verified';
  static const String selectGender = 'select_gender';
  static const String selectHobbies = 'select_hobbies';
  static const String selectFeed = 'select_feed';
  static const String sendEmote = 'send_emote';
  static const String removeEmote = 'remove_emote';
  static const String sendJoinRequestToEvent = 'send_join_request_to_event';
}

class AnalyticsParams {
  static const String universityName = 'university_name';
  static const String success = 'success';

  // SelectAttribute Evennts
  static const String value = 'value';
  static const String previousValue = 'previous';

  static const String postID = 'post_id';
  static const String eventID = 'event_id';

  static const String numberOfParticipants = 'number_of_participants';
  static const String numberOfFollowerParticipants =
      'number_of_following_participants';
  static const String numberOfNonFollowerParticipants =
      'number_of_non_follower_participants';
  static const String numberOfFolloweeParticipants =
      'number_of_followee_participants';
  static const String numberOfNonFolloweeParticipants =
      'number_of_non_followee_participants';
  static const String sameUniversityAsCreator = 'same_university_as_creator';
  static const String numberOfSameUniversityParticipants =
      'number_of_same_university_participants';
  static const String eventType = 'type';
  static const String showOnMap = 'show_on_map';
  static const String remainingTimeToStart = 'remaining_time_to_start';
  static const String eventVisibility = 'event_visibility';
}

class UniversityVerificationAnalyticsConfig {
  UniversityVerificationAnalyticsConfig({
    required this.universityName,
    required this.success,
  });

  final String universityName;
  final bool success;

  Map<String, Object> toMap() {
    return {
      AnalyticsParams.universityName: universityName,
      AnalyticsParams.success: success,
    };
  }
}

class SelectGenderAnalyticsConfig {
  SelectGenderAnalyticsConfig({
    required this.value,
    required this.previousValue,
  });

  final GenderEnum value;
  final GenderEnum previousValue;

  Map<String, Object> toMap() {
    return {
      AnalyticsParams.value: value.name,
      AnalyticsParams.previousValue: previousValue.name,
    };
  }
}

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

class SendEmoteAnalyticsConfig {
  SendEmoteAnalyticsConfig({
    required this.postID,
    required this.value,
  });

  final EmoteEnum value;
  final Identifier postID;

  Map<String, Object> toMap() {
    return {
      AnalyticsParams.value: value,
      AnalyticsParams.postID: postID,
    };
  }
}

class RemoveEmoteAnalyticsConfig {
  RemoveEmoteAnalyticsConfig({
    required this.postID,
    required this.value,
  });

  final EmoteEnum value;
  final Identifier postID;

  Map<String, Object> toMap() {
    return {
      AnalyticsParams.value: value,
      AnalyticsParams.postID: postID,
    };
  }
}
