import 'package:outnest/core/utils/types/enums/create_event_step_enum.dart';
import 'package:outnest/core/utils/types/enums/emote_enum.dart';
import 'package:outnest/core/utils/types/enums/feed_type.dart';
import 'package:outnest/core/utils/types/enums/gender_enum.dart';
import 'package:outnest/core/utils/types/enums/profile_segment_enum.dart';
import 'package:outnest/core/utils/types/enums/screen_enum.dart';
import 'package:outnest/core/utils/types/enums/visibility_enum.dart';
import 'package:outnest/core/utils/types/types.dart';

class AnalyticsEvents {
  static const String universityVerified = 'university_verified';
  static const String selectGender = 'select_gender';
  static const String selectHobbies = 'select_hobbies';
  static const String selectFeed = 'select_feed';
  static const String sendEmote = 'send_emote';
  static const String removeEmote = 'remove_emote';
  static const String sendJoinRequestToEvent = 'send_join_request_to_event';
  static const String clickSaveEvent = 'click_save_event';
  static const String clickViewEventOnMap = 'click_view_event_on_map';
  static const String clickViewEventParticipants =
      'click_view_event_participants';
  static const String pinPost = 'pin_post';
  static const String unpinPost = 'unpin_post';
  static const String createPost = 'create_post';
  static const String sendEventInvitation = 'send_event_invitation';
  static const String filterMapByCategory = 'filter_map_by_category';
  static const String filterMapByTime = 'filter_map_by_time';
  static const String filterMapByVisibility = 'filter_map_by_visibility';
  static const String createEvent = 'create_event';
  static const String failEventCreation = 'fail_event_creation';
  static const String forceStartEvent = 'force_start_event';
  static const String forceStopEvent = 'force_stop_event';
  static const String updateEventName = 'update_event_name';
  static const String updateEventStartTime = 'update_event_start_time';
  static const String updateEventVisibility = 'update_event_visibility';
  static const String updateEventLockedStatus = 'update_event_locked_status';
  static const String leaveEvent = 'leave_event';
  static const String cancelEvent = 'cancel_event';
  static const String selectProfileSegment = 'select_profile_segment';
  static const String clickHideSavedEvents = 'click_hide_saved_events';
}

class AnalyticsParams {
  static const String universityName = 'university_name';
  static const String success = 'success';

  // SelectAttribute Evennts
  static const String value = 'value';
  static const String previousValue = 'previous';

  static const String postID = 'post_id';
  static const String eventID = 'event_id';
  static const String userID = 'user_id';

  static const String toUserID = 'to_user_id';
  static const String fromUserID = 'from_user_id';

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
  static const String eventStartTime = 'event_start_time';
  static const String eventVisibility = 'event_visibility';
  static const String category = 'category';
  static const String screen = 'screen';

  static const String remainingTimeToStop = 'remaining_time_to_stop';

  static const String numberOfPhotosInPost = 'number_of_photos_in_post';
  static const String timeElapsedAfterEventStart =
      'time_elapsed_after_event_start';
  static const String addToDump = 'add_to_dump';
  static const String showParticipants = 'show_participants';
  static const String pinPost = 'pin_post';

  static const String isLocationSearched = 'is_location_searched';
  static const String hasStartTime = 'has_start_time';
  static const String isNameSuggestionUsed = 'is_name_suggestion_used';

  static const String failStep = 'fail_step';

  static const String isFollower = 'is_follower';
  static const String isFollowee = 'is_followee';
}
