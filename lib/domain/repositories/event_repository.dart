import 'package:outnest/core/utils/types/geolocation/geolocation.dart';
import 'package:outnest/core/utils/types/types.dart';
import 'package:outnest/domain/entities/feed/event/event_entity.dart';
import 'package:outnest/domain/entities/feed/event/event_messages_entity.dart';
import 'package:outnest/domain/entities/hobby/hobby_entity.dart';
import 'package:outnest/domain/entities/user/compact_user_entity.dart';

abstract class EventRepository {
  ///CRUD operations for Event entity
  Future<void> createEvent(EventEntity event);
  Future<void> updateEvent(String eventId, Map<String, dynamic> changes);
  Future<void> deleteEvent(Identifier eventId);
  Future<EventEntity?> getEvent(Identifier eventId);
  Future<List<EventEntity>> getEventsByIds(
    List<Identifier> eventIds,
  );
  Future<EventEntity> enrichEventWithDetails(EventEntity event);

  Stream<List<EventEntity>> getEnrichedEventsOfUserStream(Identifier userId);

  /// Messages Subcollection
  Future<void> addMessage(Identifier eventId, EventMessagesEntity message);
  Future<List<EventMessagesEntity>> getMessages(Identifier eventId);
  Future<List<EventMessagesEntity>> getMessagesByUser(
    Identifier eventId,
    Identifier userId,
  );
  Future<void> deleteMessage(Identifier eventId, Identifier messageId);

  /// Participants Subcollection

  Future<void> requestJoin(
    Identifier eventId,
    CompactUserEntity participant,
  );
  Future<void> acceptParticipant(
    String eventId,
    CompactUserEntity participant,
  );
  Future<void> rejectRequest(
    Identifier eventId,
    CompactUserEntity participant,
  );

  Future<void> updateParticipant(
    Identifier eventId,
    EventParticipantEntity participant,
  );
  Future<void> removeParticipant(Identifier eventId, CompactUserEntity user);

  /// === Query & Search ===

  bool canUserJoinEvent(
    EventEntity event,
    Identifier user,
  );

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
