import 'package:bulusalim/core/utils/types/geolocation/geolocation.dart';
import 'package:bulusalim/core/utils/types/types.dart';
import 'package:bulusalim/domain/feed/event/event_entity.dart';
import 'package:bulusalim/domain/feed/event/event_messages_entity.dart';

import 'package:bulusalim/domain/entities/hobby/hobby_entity.dart';

abstract class EventRepository {
  ///CRUD operations for Event entity
  Future<void> createEvent(EventEntity event);
  Future<void> updateEvent(EventEntity event);
  Future<void> deleteEvent(Identifier eventId);
  Future<EventEntity?> getEvent(Identifier eventId);

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
    ParticipantEntity participant,
  );

  Future<void> updateParticipant(
    Identifier eventId,
    ParticipantEntity participant,
  );
  Future<void> removeParticipant(
    Identifier eventId,
    Identifier userId,
  );

  /// === Query & Search ===

  Future<List<EventEntity>> getAllEvents();
  Future<List<EventEntity>> searchEventsByTitle(String title);
  Future<List<EventEntity>> getEventsByAttribute(
    String key,
    dynamic value,
  );

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
