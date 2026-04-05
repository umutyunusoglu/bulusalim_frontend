import 'dart:async';

import 'package:outnest/application/get_it_service_locators/get_it_init.dart';
import 'package:outnest/core/utils/logging/logging_service.dart';
import 'package:outnest/core/utils/types/enums/screen_enum.dart';
import 'package:outnest/domain/entities/feed/event/event_entity.dart';
import 'package:outnest/domain/entities/user/compact_user_entity.dart';
import 'package:outnest/domain/repositories/event_repository.dart';
import 'package:outnest/domain/services/analytics/analytics_service.dart';
import 'package:outnest/domain/services/analytics/event_configs/send_join_request_to_event_analytics_config.dart';
import 'package:outnest/domain/services/session_service.dart';

enum EventJoinStatus { canJoin, pending, joined }

class EventJoinController {
  EventJoinController({required this.event})
    : _eventRepository = getIt<EventRepository>(),
      _sessionService = getIt<SessionService>(),
      _analyticsService = getIt<AnalyticsService>(),
      _logger = getIt<LoggingService>();

  final EventEntity event;
  final EventRepository _eventRepository;
  final SessionService _sessionService;
  final AnalyticsService _analyticsService;
  final LoggingService _logger;

  CompactUserEntity _currentUserCompact() {
    final u = _sessionService.currentUser!;
    return CompactUserEntity(
      userID: u.userID,
      username: u.username,
      profileImageUrl: u.profileImageUrl,
      university: u.university,
      nameSurname: u.nameSurname,
      isPrivate: u.isPrivate,
      bio: u.bio,
      accountType: u.accountType,
      communityData: null,
    );
  }

  /// Katılma isteği gönderir.
  /// Başarılıysa `null`, hata varsa hata mesajı döner.
  Future<String?> requestJoin({required ScreenEnum screen}) async {
    if (_sessionService.currentUser == null) return 'Oturum bulunamadı.';

    try {
      final compactUser = _currentUserCompact();
      await _eventRepository.requestJoin(event.id, compactUser);
      event.requestPool.add(compactUser);
      _logJoinAnalytics(screen: screen);
      return null;
    } catch (e) {
      _logger.error('Join request failed: $e');
      return 'İstek gönderilemedi, tekrar deneyin.';
    }
  }

  /// Katılma isteğini geri alır.
  /// Başarılıysa `null`, hata varsa hata mesajı döner.
  Future<String?> withdrawRequest() async {
    final currentUser = _sessionService.currentUser;
    if (currentUser == null) return 'Oturum bulunamadı.';

    try {
      final compactUser = _currentUserCompact();
      await _eventRepository.withdrawJoinRequest(event.id, compactUser);
      event.requestPool.removeWhere((p) => p.userID == currentUser.userID);
      return null;
    } catch (e) {
      _logger.error('Withdraw request failed: $e');
      return 'İstek geri alınamadı, tekrar deneyin.';
    }
  }

  // ─── ANALİTİK ───
  void _logJoinAnalytics({required ScreenEnum screen}) {
    final sameUniversityAsCreator =
        _sessionService.currentUser?.university != null &&
        _sessionService.currentUser!.university == event.creator.university;

    final followers = _sessionService.stateListenable.value?.followers ?? [];
    final followees = _sessionService.stateListenable.value?.followees ?? [];

    final numberOfFollowerParticipants = event.participants
        .where((p) => followers.any((u) => u.userID == p.userID))
        .length;

    final numberOfFolloweeParticipants = event.participants
        .where((p) => followees.any((u) => u.userID == p.userID))
        .length;

    final numberOfSameUniversityParticipants = event.participants
        .where(
          (p) => p.university == _sessionService.currentUser?.university,
        )
        .length;

    unawaited(
      _analyticsService.logSendJoinRequestToEvent(
        SendJoinRequestToEventAnalyticsConfig(
          eventID: event.id,
          numberOfParticipants: event.participantCount,
          numberOfFollowerParticipants: numberOfFollowerParticipants,
          numberOfNonFollowerParticipants:
              event.participants.length - numberOfFollowerParticipants,
          numberOfFolloweeParticipants: numberOfFolloweeParticipants,
          numberOfNonFolloweeParticipants:
              event.participants.length - numberOfFolloweeParticipants,
          sameUniversityAsCreator: sameUniversityAsCreator,
          numberOfSameUniversityParticipants:
              numberOfSameUniversityParticipants,
          showOnMap: event.showOnMap,
          remainingTimeToStart: event.startTime.difference(DateTime.now()),
          eventStartTime: event.startTime,
          eventVisibility: event.visibility.toString(),
          category: event.hobbies.isNotEmpty ? event.hobbies[0] : 'null',
          screen: screen,
        ),
      ),
    );
  }
}
