import 'package:bulusalim/core/utils/types/geolocation/geolocation.dart';
import 'package:bulusalim/core/utils/types/types.dart';
import 'package:bulusalim/domain/entities/feed/event/event_entity.dart';
import 'package:bulusalim/domain/entities/feed/event/event_messages_entity.dart';
import 'package:bulusalim/domain/entities/hobby/hobby_entity.dart';

abstract class EventRepository {
  ///CRUD operations for Event entity
  Future<void> createEvent(EventEntity event);
  Future<void> updateEvent(String eventId, Map<String, dynamic> changes);
  Future<void> deleteEvent(Identifier eventId);
  Future<EventEntity?> getEvent(Identifier eventId, {bool loadDetails = true});
  Future<List<EventEntity>> getEventsByIds(
    List<Identifier> eventIds, {
    bool loadDetails = true,
  });
  Future<EventEntity> enrichEventWithDetails(EventEntity event);

  /// Messages Subcollection
  Future<void> addMessage(Identifier eventId, EventMessagesEntity message);
  Future<List<EventMessagesEntity>> getMessages(Identifier eventId);
  Future<List<EventMessagesEntity>> getMessagesByUser(
    Identifier eventId,
    Identifier userId,
  );
  Future<void> deleteMessage(Identifier eventId, Identifier messageId);

  /// Participants Subcollection
  Future<void> addParticipant(
    Identifier eventId,
    EventParticipantEntity participant,
  );

  Future<void> requestJoin(
    Identifier eventId,
    EventParticipantEntity participant,
  );
  Future<void> acceptParticipant(
    Identifier eventId,
    Identifier userId,
  );
  Future<void> rejectOrCancelRequest(
    Identifier eventId,
    Identifier userId,
  );

  Future<void> updateParticipant(
    Identifier eventId,
    EventParticipantEntity participant,
  );
  Future<void> removeParticipant(Identifier eventId, Identifier userId);

  /// === Query & Search ===

  Future<List<EventEntity>> getAllEvents();
  Future<List<EventEntity>> searchEventsByTitle(String title);

  Future<List<EventEntity>> getEventsByLocation(
    Geolocation location,
    double radiusInKm,
  );
  Future<List<EventEntity>> getEventsByDateRange(
    DateTime startDate,
    DateTime endDate,
  );
  Future<List<EventEntity>> getEventsByHobby(
    List<HobbyEntity> categories,
  );
}
