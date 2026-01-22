import 'package:bulusalim/core/utils/logging/logging_service.dart';
import 'package:bulusalim/core/utils/types/enums/event_status_enum.dart';
import 'package:bulusalim/domain/entities/feed/event/event_entity.dart';
import 'package:bulusalim/domain/repositories/event_repository.dart';
import 'package:bulusalim/domain/repositories/user_repository.dart';

class ForceStartEvent {
  ForceStartEvent({
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
      _logger.info('Force starting event: ${currentEvent.eventID}');

      // 1. Etkinlik durumunu güncelle
      await _eventRepository.updateEvent(
        currentEvent.eventID,
        {'status': EventStatusEnum.ongoing.value},
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
                  .ongoing
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
        'Event ${currentEvent.eventID} and all participant logs updated to ongoing.',
      );
    } catch (e) {
      _logger.error('Error in ForceStartEvent: $e');
      rethrow;
    }
  }
}
