import 'package:outnest/domain/services/analytics/analytics_constants.dart';
import 'package:outnest/domain/services/analytics/event_configs/cancel_event_analytics_config.dart';
import 'package:outnest/domain/services/analytics/event_configs/click_hide_saved_events_analytics_config.dart';
import 'package:outnest/domain/services/analytics/event_configs/click_save_event_analytics_config.dart';
import 'package:outnest/domain/services/analytics/event_configs/click_view_event_on_map_analytics_config.dart';
import 'package:outnest/domain/services/analytics/event_configs/click_view_event_participants_analytics_config.dart';
import 'package:outnest/domain/services/analytics/event_configs/create_event_analytics_config.dart';
import 'package:outnest/domain/services/analytics/event_configs/create_post_analytics_config.dart';
import 'package:outnest/domain/services/analytics/event_configs/fail_event_creation_analytics_config.dart';
import 'package:outnest/domain/services/analytics/event_configs/filter_map_by_category_analytics_config.dart';
import 'package:outnest/domain/services/analytics/event_configs/filter_map_by_time_analytics_config.dart';
import 'package:outnest/domain/services/analytics/event_configs/filter_map_by_visibility_analytics_config.dart';
import 'package:outnest/domain/services/analytics/event_configs/force_start_event_analytics_config.dart';
import 'package:outnest/domain/services/analytics/event_configs/force_stop_event_analytics_config.dart';
import 'package:outnest/domain/services/analytics/event_configs/leave_event_analytics_config.dart';
import 'package:outnest/domain/services/analytics/event_configs/pin_post_analytics_config.dart';
import 'package:outnest/domain/services/analytics/event_configs/remove_emote_analytics_config.dart';
import 'package:outnest/domain/services/analytics/event_configs/select_feed_analytics_config.dart';
import 'package:outnest/domain/services/analytics/event_configs/select_gender_analytics_config.dart';
import 'package:outnest/domain/services/analytics/event_configs/select_hobbies_analytics_config.dart';
import 'package:outnest/domain/services/analytics/event_configs/select_profile_segment_analytics_config.dart';
import 'package:outnest/domain/services/analytics/event_configs/send_emote_analytics_config.dart';
import 'package:outnest/domain/services/analytics/event_configs/send_event_invitation_analytics_config.dart';
import 'package:outnest/domain/services/analytics/event_configs/send_join_request_to_event_analytics_config.dart';
import 'package:outnest/domain/services/analytics/event_configs/university_verification_analytics_config.dart';
import 'package:outnest/domain/services/analytics/event_configs/unpin_post_analytics_config.dart';
import 'package:outnest/domain/services/analytics/event_configs/update_event_location_analytics_config.dart';
import 'package:outnest/domain/services/analytics/event_configs/update_event_locked_status_analytics_config.dart';
import 'package:outnest/domain/services/analytics/event_configs/update_event_name_analytics_config.dart';
import 'package:outnest/domain/services/analytics/event_configs/update_event_start_time_analytics_config.dart';
import 'package:outnest/domain/services/analytics/event_configs/update_event_visibility_analytics_config.dart';

extension on Map<String, dynamic> {
  /// Converts all boolean values to 1/0 for Firebase compatibility
  Map<String, dynamic> cleanForFirebaseAnalytics() {
    return map((key, value) {
      if (value is bool) return MapEntry(key, value ? 1 : 0);
      return MapEntry(key, value);
    });
  }
}

abstract class AnalyticsService {
  Future<void> logAnalytic(String eventName, Map<String, dynamic> parameters);

  Future<void> logUniversityVerified(
    UniversityVerificationAnalyticsConfig config,
  ) async {
    await logAnalytic(
      AnalyticsEvents.universityVerified,
      config.toMap().cleanForFirebaseAnalytics(),
    );
  }

  Future<void> logSelectGender(SelectGenderAnalyticsConfig config) async {
    await logAnalytic(
      AnalyticsEvents.selectGender,
      config.toMap().cleanForFirebaseAnalytics(),
    );
  }

  Future<void> logSelectHobbies(SelectHobbiesAnalyticsConfig config) async {
    await logAnalytic(
      AnalyticsEvents.selectHobbies,
      config.toMap().cleanForFirebaseAnalytics(),
    );
  }

  Future<void> logSelectFeed(SelectFeedAnalyticsConfig config) async {
    await logAnalytic(
      AnalyticsEvents.selectFeed,
      config.toMap().cleanForFirebaseAnalytics(),
    );
  }

  Future<void> logSendEmote(SendEmoteAnalyticsConfig config) async {
    await logAnalytic(
      AnalyticsEvents.sendEmote,
      config.toMap().cleanForFirebaseAnalytics(),
    );
  }

  Future<void> logRemoveEmote(RemoveEmoteAnalyticsConfig config) async {
    await logAnalytic(
      AnalyticsEvents.removeEmote,
      config.toMap().cleanForFirebaseAnalytics(),
    );
  }

  Future<void> logSendJoinRequestToEvent(
    SendJoinRequestToEventAnalyticsConfig config,
  ) async {
    await logAnalytic(
      AnalyticsEvents.sendJoinRequestToEvent,
      config.toMap().cleanForFirebaseAnalytics(),
    );
  }

  Future<void> logClickSaveEvent(ClickSaveEventAnalyticsConfig config) async {
    await logAnalytic(
      AnalyticsEvents.clickSaveEvent,
      config.toMap().cleanForFirebaseAnalytics(),
    );
  }

  Future<void> logClickViewEventOnMap(
    ClickViewEventOnMapAnalyticsConfig config,
  ) async {
    await logAnalytic(
      AnalyticsEvents.clickViewEventOnMap,
      config.toMap().cleanForFirebaseAnalytics(),
    );
  }

  Future<void> logClickViewEventParticipants(
    ClickViewEventParticipantsAnalyticsConfig config,
  ) async {
    await logAnalytic(
      AnalyticsEvents.clickViewEventParticipants,
      config.toMap().cleanForFirebaseAnalytics(),
    );
  }

  Future<void> logPinPost(PinPostAnalyticsConfig config) async {
    await logAnalytic(
      AnalyticsEvents.pinPost,
      config.toMap().cleanForFirebaseAnalytics(),
    );
  }

  Future<void> logUnpinPost(UnpinPostAnalyticsConfig config) async {
    await logAnalytic(
      AnalyticsEvents.unpinPost,
      config.toMap().cleanForFirebaseAnalytics(),
    );
  }

  Future<void> logCreatePost(CreatePostAnalyticsConfig config) async {
    await logAnalytic(
      AnalyticsEvents.createPost,
      config.toMap().cleanForFirebaseAnalytics(),
    );
  }

  Future<void> logSendEventInvitation(
    SendEventInvitationAnalyticsConfig config,
  ) async {
    await logAnalytic(
      AnalyticsEvents.sendEventInvitation,
      config.toMap().cleanForFirebaseAnalytics(),
    );
  }

  Future<void> logFilterMapByCategory(
    FilterMapByCategoryAnalyticsConfig config,
  ) async {
    await logAnalytic(
      AnalyticsEvents.filterMapByCategory,
      config.toMap().cleanForFirebaseAnalytics(),
    );
  }

  Future<void> logFilterMapByTime(FilterMapByTimeAnalyticsConfig config) async {
    await logAnalytic(
      AnalyticsEvents.filterMapByTime,
      config.toMap().cleanForFirebaseAnalytics(),
    );
  }

  Future<void> logFilterMapByVisibility(
    FilterMapByVisibilityAnalyticsConfig config,
  ) async {
    await logAnalytic(
      AnalyticsEvents.filterMapByVisibility,
      config.toMap().cleanForFirebaseAnalytics(),
    );
  }

  Future<void> logCreateEvent(CreateEventAnalyticsConfig config) async {
    await logAnalytic(
      AnalyticsEvents.createEvent,
      config.toMap().cleanForFirebaseAnalytics(),
    );
  }

  Future<void> logFailEventCreation(
    FailEventCreationAnalyticsConfig config,
  ) async {
    await logAnalytic(
      AnalyticsEvents.failEventCreation,
      config.toMap().cleanForFirebaseAnalytics(),
    );
  }

  Future<void> logForceStartEvent(ForceStartEventAnalyticsConfig config) async {
    await logAnalytic(
      AnalyticsEvents.forceStartEvent,
      config.toMap().cleanForFirebaseAnalytics(),
    );
  }

  Future<void> logForceStopEvent(ForceStopEventAnalyticsConfig config) async {
    await logAnalytic(
      AnalyticsEvents.forceStopEvent,
      config.toMap().cleanForFirebaseAnalytics(),
    );
  }

  Future<void> logUpdateEventName(UpdateEventNameAnalyticsConfig config) async {
    await logAnalytic(
      AnalyticsEvents.updateEventName,
      config.toMap().cleanForFirebaseAnalytics(),
    );
  }

  Future<void> logUpdateEventStartTime(
    UpdateEventStartTimeAnalyticsConfig config,
  ) async {
    await logAnalytic(
      AnalyticsEvents.updateEventStartTime,
      config.toMap().cleanForFirebaseAnalytics(),
    );
  }

  Future<void> logUpdateEventVisibility(
    UpdateEventVisibilityAnalyticsConfig config,
  ) async {
    await logAnalytic(
      AnalyticsEvents.updateEventVisibility,
      config.toMap().cleanForFirebaseAnalytics(),
    );
  }

  Future<void> logUpdateEventLockedStatus(
    UpdateEventLockedStatusAnalyticsConfig config,
  ) async {
    await logAnalytic(
      AnalyticsEvents.updateEventLockedStatus,
      config.toMap().cleanForFirebaseAnalytics(),
    );
  }

  Future<void> logLeaveEvent(LeaveEventAnalyticsConfig config) async {
    await logAnalytic(
      AnalyticsEvents.leaveEvent,
      config.toMap().cleanForFirebaseAnalytics(),
    );
  }

  Future<void> logCancelEvent(CancelEventAnalyticsConfig config) async {
    await logAnalytic(
      AnalyticsEvents.cancelEvent,
      config.toMap().cleanForFirebaseAnalytics(),
    );
  }

  Future<void> logSelectProfileSegment(
    SelectProfileSegmentAnalyticsConfig config,
  ) async {
    await logAnalytic(
      AnalyticsEvents.selectProfileSegment,
      config.toMap().cleanForFirebaseAnalytics(),
    );
  }

  Future<void> logClickHideSavedEvents(
    ClickHideSavedEventsAnalyticsConfig config,
  ) async {
    await logAnalytic(
      AnalyticsEvents.clickHideSavedEvents,
      config.toMap().cleanForFirebaseAnalytics(),
    );
  }

  void logUpdateEventLocation(
    UpdateEventLocationAnalyticsConfig updateEventLocationAnalyticsConfig,
  ) {
    logAnalytic(
      AnalyticsEvents.updateEventLocation,
      updateEventLocationAnalyticsConfig.toMap().cleanForFirebaseAnalytics(),
    );
  }
}
