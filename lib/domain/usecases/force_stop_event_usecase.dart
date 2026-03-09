import 'package:outnest/application/providers/get_it_init.dart';
import 'package:outnest/core/utils/logging/logging_service.dart';
import 'package:outnest/core/utils/types/enums/event_status_enum.dart';
import 'package:outnest/domain/entities/feed/event/event_entity.dart';
import 'package:outnest/domain/repositories/event_repository.dart';
import 'package:outnest/domain/repositories/user_repository.dart';
import 'package:outnest/domain/services/analytics/analytics_service.dart';
import 'package:outnest/domain/services/analytics/event_configs/force_stop_event_analytics_config.dart';

class ForceStopEvent {
  ForceStopEvent({
    required LoggingService logger,
    required EventRepository eventRepository,
    required UserRepository userRepository,
  }) : _logger = logger,
       _eventRepository = eventRepository,
       _userRepository = userRepository;

  final LoggingService _logger;
  final EventRepository _eventRepository;
  final UserRepository _userRepository;

  Future<void> call(EventEntity currentEvent) async {
    try {
      _logger.info('Force stopping event: ${currentEvent.eventID}');

      // 1. buluşma durumunu güncelle
      await _eventRepository.updateEvent(
        currentEvent.eventID,
        {'status': EventStatusEnum.completed.value},
      );

      // 2. Detayları getir (Katılımcılar için)
      final enrichedEvent = await _eventRepository.enrichEventWithDetails(
        currentEvent,
      );

      final participants = enrichedEvent.participants;

      if (participants.isEmpty) {
        _logger.warn(
          'No participants found for event ${currentEvent.eventID}',
        );
        return;
      }

      // 3. Kullanıcı loglarını paralel olarak güncelle
      // Future.wait kullanarak tüm işlemleri aynı anda başlatıyoruz
      await Future.wait(
        participants.map((participant) async {
          try {
            await _userRepository.updateUserEventLogStatus(
              participant.userID,
              enrichedEvent.eventID,
              EventStatusEnum
                  .completed
                  .value, // String yerine enum kullanmak daha güvenli
            );
          } catch (e) {
            _logger.error(
              'Failed to update log for user ${participant.userID}: $e',
            );
            // Bir kullanıcıda hata olması diğerlerini durdurmasın diye try-catch içinde
          }
        }),
      );

      _logger.info(
        'Event ${currentEvent.eventID} and all participant logs updated to completed.',
      );

      getIt<AnalyticsService>().logForceStopEvent(
        ForceStopEventAnalyticsConfig(
          eventID: enrichedEvent.eventID,
          timeToEventToStop: DateTime.now().difference(enrichedEvent.startTime),
        ),
      );
    } catch (e) {
      _logger.error('Error in ForceStopEvent: $e');
      rethrow;
    }
  }
}
