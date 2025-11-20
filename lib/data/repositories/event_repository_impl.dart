import 'package:bulusalim/core/utils/logging/logging_service.dart';
import 'package:bulusalim/core/utils/types/geolocation/geolocation.dart';
import 'package:bulusalim/core/utils/types/types.dart';
import 'package:bulusalim/data/models/event/event_messages_model.dart';
import 'package:bulusalim/data/models/event/event_model.dart';
import 'package:bulusalim/domain/entities/hobby/hobby_entity.dart';
import 'package:bulusalim/domain/feed/event/event_entity.dart';
import 'package:bulusalim/domain/feed/event/event_messages_entity.dart';
import 'package:bulusalim/domain/repositories/event_repository.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class EventRepositoryImpl implements EventRepository {
  EventRepositoryImpl({
    required FirebaseFirestore firestore,
    required LoggingService logger,
  }) : _firestore = firestore,
       _logger = logger;

  final FirebaseFirestore _firestore;
  final LoggingService _logger;

  ///CRUD operations for Event entity
  @override
  Future<void> createEvent(EventEntity event) async {
    try {
      final docRef = _firestore.collection('events').doc();

      final eventWithId = event.copyWith(eventID: docRef.id);

      final eventModel = EventModel.fromEntity(eventWithId);

      await docRef.set(eventModel.toFirestore());

      _logger.info('Event created with ID: ${docRef.id}');
    } catch (e) {
      _logger.error('Failed to create event: $e');
      rethrow;
    }
  }

  @override
  Future<void> updateEvent(EventEntity event) async {
    final eventModel = EventModel.fromEntity(event);
    try {
      await _firestore
          .collection('events')
          .doc(event.eventID)
          .update(eventModel.toFirestore());
    } catch (e) {
      _logger.error('Failed to update event: $e');
      rethrow;
    }
  }

  @override
  Future<void> deleteEvent(Identifier eventId) async {
    try {
      await _firestore.collection('users').doc(eventId).delete();
    } on Exception catch (e) {
      _logger.error('Failed to delete event::$e');
      rethrow;
    }
  }

  @override
  Future<EventEntity?> getEvent(Identifier eventId) async {
    try {
      final doc = await _firestore.collection('events').doc(eventId).get();
      if (doc.exists) {
        final eventModel = EventModel.fromFirestore(doc.data()!);
        return eventModel.toEntity();
      }
    } on Exception {
      _logger.error('Failed to fetch event');
      rethrow;
    }
    return null;
  }

  /// Messages Subcollection
  @override
  Future<void> addMessage(Identifier eventId, EventMessagesEntity message) {
    try {
      final messageDocRef = _firestore
          .collection('events')
          .doc(eventId)
          .collection('messages')
          .doc();

      final messageWithId = message.copyWith(messageID: messageDocRef.id);
      final messageModel = EventMessagesModel.fromEntity(messageWithId);
      return messageDocRef.set(messageModel.toFirestore());
    } on Exception catch (e) {
      _logger.error('Failed to add message: $e');
      rethrow;
    }
  }

  @override
  Future<List<EventMessagesEntity>> getMessages(Identifier eventId) async {
    return _firestore
        .collection('events')
        .doc(eventId)
        .collection('messages')
        .get()
        .then(
          (snapshot) => snapshot.docs
              .map(
                (doc) =>
                    EventMessagesModel.fromFirestore(doc.data()).toEntity(),
              )
              .toList(),
        );
  }

  @override
  Future<List<EventMessagesEntity>> getMessagesByUser(
    Identifier eventId,
    Identifier userId,
  ) {
    return _firestore
        .collection('events')
        .doc(eventId)
        .collection('messages')
        .where('senderId', isEqualTo: userId)
        .get()
        .then(
          (snapshot) => snapshot.docs
              .map(
                (doc) =>
                    EventMessagesModel.fromFirestore(doc.data()).toEntity(),
              )
              .toList(),
        );
  }

  @override
  Future<void> deleteMessage(Identifier eventId, Identifier messageId) {
    return _firestore
        .collection('events')
        .doc(eventId)
        .collection('messages')
        .doc(messageId)
        .delete();
  }

  /// Participants Subcollection
  @override
  Future<void> addParticipant(
    Identifier eventId,
    ParticipantEntity participant,
  ) async {
    throw UnimplementedError();
  }

  @override
  Future<void> updateParticipant(
    Identifier eventId,
    ParticipantEntity participant,
  ) async {
    throw UnimplementedError();
  }

  @override
  Future<void> removeParticipant(
    Identifier eventId,
    Identifier userId,
  ) {
    throw UnimplementedError();
  }

  /// Query and Search

  @override
  Future<List<EventEntity>> getAllEvents() async {
    try {
      final querySnapshot = await _firestore.collection('events').get();
      return querySnapshot.docs
          .map((doc) => EventModel.fromFirestore(doc.data()).toEntity())
          .toList();
    } on Exception catch (e) {
      _logger.error('Failed to get all events: $e');
      rethrow;
    }
  }

  @override
  Future<List<EventEntity>> searchEventsByTitle(String title) async {
    try {
      final querySnapshot = await _firestore
          .collection('events')
          .where('name', isEqualTo: title) // TODO: Improve search logic
          .get();

      return querySnapshot.docs
          .map((doc) => EventModel.fromFirestore(doc.data()).toEntity())
          .toList();
    } on Exception catch (e) {
      _logger.error('Failed to search events by title: $e');
      rethrow;
    }
  }

  @override
  Future<List<EventEntity>> getEventsByAttribute(
    String key,
    dynamic value,
  ) async {
    try {
      final querySnapshot = await _firestore
          .collection('events')
          .where('attributes.$key', isEqualTo: value)
          .get();
      return querySnapshot.docs
          .map((doc) => EventModel.fromFirestore(doc.data()).toEntity())
          .toList();
    } on Exception catch (e) {
      _logger.error('Failed to get events by attribute: $e');
      rethrow;
    }
  }

  @override
  Future<List<EventEntity>> getEventsByLocation(
    Geolocation location,
    double radiusInKm,
  ) {
    throw UnimplementedError();
  }

  @override
  Future<List<EventEntity>> getEventsByDateRange(
    DateTime startDate,
    DateTime endDate,
  ) {
    throw UnimplementedError();
  }

  @override
  Future<List<EventEntity>> getEventsByHobby(
    List<HobbyEntity> categories,
  ) {
    throw UnimplementedError();
  }
}
