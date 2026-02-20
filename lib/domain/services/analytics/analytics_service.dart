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

abstract class AnalyticsService {
  Future<void> logAnalytic(String eventName, Map<String, dynamic> parameters);

  Future<void> logUniversityVerified(
    UniversityVerificationAnalyticsConfig config,
  ) async {
    await logAnalytic(AnalyticsEvents.universityVerified, config.toMap());
  }

  Future<void> logSelectGender(SelectGenderAnalyticsConfig config) async {
    await logAnalytic(AnalyticsEvents.selectGender, config.toMap());
  }

  Future<void> logSelectHobbies(SelectHobbiesAnalyticsConfig config) async {
    await logAnalytic(AnalyticsEvents.selectHobbies, config.toMap());
  }

  Future<void> logSelectFeed(SelectFeedAnalyticsConfig config) async {
    await logAnalytic(AnalyticsEvents.selectFeed, config.toMap());
  }

  Future<void> logSendEmote(SendEmoteAnalyticsConfig config) async {
    await logAnalytic(AnalyticsEvents.sendEmote, config.toMap());
  }

  Future<void> logRemoveEmote(RemoveEmoteAnalyticsConfig config) async {
    await logAnalytic(AnalyticsEvents.removeEmote, config.toMap());
  }

  Future<void> logSendJoinRequestToEvent(
    SendJoinRequestToEventAnalyticsConfig config,
  ) async {
    await logAnalytic(AnalyticsEvents.sendJoinRequestToEvent, config.toMap());
  }

  Future<void> logClickSaveEvent(ClickSaveEventAnalyticsConfig config) async {
    await logAnalytic(AnalyticsEvents.clickSaveEvent, config.toMap());
  }

  Future<void> logClickViewEventOnMap(
    ClickViewEventOnMapAnalyticsConfig config,
  ) async {
    await logAnalytic(AnalyticsEvents.clickViewEventOnMap, config.toMap());
  }

  Future<void> logClickViewEventParticipants(
    ClickViewEventParticipantsAnalyticsConfig config,
  ) async {
    await logAnalytic(
      AnalyticsEvents.clickViewEventParticipants,
      config.toMap(),
    );
  }

  Future<void> logPinPost(PinPostAnalyticsConfig config) async {
    await logAnalytic(AnalyticsEvents.pinPost, config.toMap());
  }

  Future<void> logUnpinPost(UnpinPostAnalyticsConfig config) async {
    await logAnalytic(AnalyticsEvents.unpinPost, config.toMap());
  }

  Future<void> logCreatePost(CreatePostAnalyticsConfig config) async {
    await logAnalytic(AnalyticsEvents.createPost, config.toMap());
  }

  Future<void> logSendEventInvitation(
    SendEventInvitationAnalyticsConfig config,
  ) async {
    await logAnalytic(AnalyticsEvents.sendEventInvitation, config.toMap());
  }

  Future<void> logFilterMapByCategory(
    FilterMapByCategoryAnalyticsConfig config,
  ) async {
    await logAnalytic(AnalyticsEvents.filterMapByCategory, config.toMap());
  }

  Future<void> logFilterMapByTime(FilterMapByTimeAnalyticsConfig config) async {
    await logAnalytic(AnalyticsEvents.filterMapByTime, config.toMap());
  }

  Future<void> logFilterMapByVisibility(
    FilterMapByVisibilityAnalyticsConfig config,
  ) async {
    await logAnalytic(AnalyticsEvents.filterMapByVisibility, config.toMap());
  }

  Future<void> logCreateEvent(CreateEventAnalyticsConfig config) async {
    await logAnalytic(AnalyticsEvents.createEvent, config.toMap());
  }

  Future<void> logFailEventCreation(
    FailEventCreationAnalyticsConfig config,
  ) async {
    await logAnalytic(AnalyticsEvents.failEventCreation, config.toMap());
  }

  Future<void> logForceStartEvent(ForceStartEventAnalyticsConfig config) async {
    await logAnalytic(AnalyticsEvents.forceStartEvent, config.toMap());
  }

  Future<void> logForceStopEvent(ForceStopEventAnalyticsConfig config) async {
    await logAnalytic(AnalyticsEvents.forceStopEvent, config.toMap());
  }

  Future<void> logUpdateEventName(UpdateEventNameAnalyticsConfig config) async {
    await logAnalytic(AnalyticsEvents.updateEventName, config.toMap());
  }

  Future<void> logUpdateEventStartTime(
    UpdateEventStartTimeAnalyticsConfig config,
  ) async {
    await logAnalytic(AnalyticsEvents.updateEventStartTime, config.toMap());
  }

  Future<void> logUpdateEventVisibility(
    UpdateEventVisibilityAnalyticsConfig config,
  ) async {
    await logAnalytic(AnalyticsEvents.updateEventVisibility, config.toMap());
  }

  Future<void> logUpdateEventLockedStatus(
    UpdateEventLockedStatusAnalyticsConfig config,
  ) async {
    await logAnalytic(AnalyticsEvents.updateEventLockedStatus, config.toMap());
  }

  Future<void> logLeaveEvent(LeaveEventAnalyticsConfig config) async {
    await logAnalytic(AnalyticsEvents.leaveEvent, config.toMap());
  }

  Future<void> logCancelEvent(CancelEventAnalyticsConfig config) async {
    await logAnalytic(AnalyticsEvents.cancelEvent, config.toMap());
  }

  Future<void> logSelectProfileSegment(
    SelectProfileSegmentAnalyticsConfig config,
  ) async {
    await logAnalytic(AnalyticsEvents.selectProfileSegment, config.toMap());
  }

  Future<void> logClickHideSavedEvents(
    ClickHideSavedEventsAnalyticsConfig config,
  ) async {
    await logAnalytic(AnalyticsEvents.clickHideSavedEvents, config.toMap());
  }

  void logUpdateEventLocation(
    UpdateEventLocationAnalyticsConfig updateEventLocationAnalyticsConfig,
  ) {}
}
