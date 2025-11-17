import 'package:bulusalim/core/utils/logging/logging_service.dart';
import 'package:bulusalim/core/utils/types/geolocation/geolocation.dart';
import 'package:bulusalim/core/utils/types/types.dart';
import 'package:bulusalim/data/models/event/event_messages_model.dart';
import 'package:bulusalim/data/models/event/event_model.dart';
import 'package:bulusalim/data/models/event/participant_model.dart';
import 'package:bulusalim/data/models/event/participant_rating_model.dart';
import 'package:bulusalim/domain/feed/event/event_entity.dart';
import 'package:bulusalim/domain/feed/event/event_messages_entity.dart';
import 'package:bulusalim/domain/feed/event/participant_entity.dart';
import 'package:bulusalim/domain/feed/event/participant_rating_entity.dart';
import 'package:bulusalim/domain/entities/hobby/hobby_entity.dart';
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
    ParticipantEntity participant,
  ) async {
    try {
      final participantDocRef = _firestore
          .collection('events')
          .doc(participant.eventID)
          .collection('participants')
          .doc(participant.userID);

      //For safety, ensure the userID is set correctly
      final participantWithId = participant.copyWith(
        userID: participantDocRef.id,
      );

      final participantModel = ParticipantModel.fromEntity(participantWithId);

      await participantDocRef.set(participantModel.toFirestore());
    } on Exception catch (e) {
      _logger.error('Failed to add participant: $e');
      rethrow;
    }
  }

  @override
  Future<void> updateParticipant(
    ParticipantEntity participant,
  ) async {
    try {
      final participantModel = ParticipantModel.fromEntity(participant);
      await _firestore
          .collection('events')
          .doc(participant.eventID)
          .collection('participants')
          .doc(participant.userID)
          .update(participantModel.toFirestore());
    } on Exception catch (e) {
      _logger.error('Failed to update participant: $e');
      rethrow;
    }
  }

  @override
  Future<void> removeParticipant(
    Identifier eventId,
    Identifier userId,
  ) {
    return _firestore
        .collection('events')
        .doc(eventId)
        .collection('participants')
        .doc(userId)
        .delete();
  }

  @override
  Future<List<ParticipantEntity>> getParticipants(Identifier eventId) {
    return _firestore
        .collection('events')
        .doc(eventId)
        .collection('participants')
        .get()
        .then(
          (snapshot) => snapshot.docs
              .map(
                (doc) => ParticipantModel.fromFirestore(doc.data()).toEntity(),
              )
              .toList(),
        );
  }

  @override
  Future<ParticipantEntity?> getEventParticipant(
    Identifier eventId,
    Identifier userId,
  ) {
    return _firestore
        .collection('events')
        .doc(eventId)
        .collection('participants')
        .doc(userId)
        .get()
        .then(
          (doc) {
            if (doc.exists) {
              return ParticipantModel.fromFirestore(doc.data()!).toEntity();
            }
            return null;
          },
        );
  }

  /// Participant Ratings Subcollection
  @override
  Future<void> addParticipantRating(
    ParticipantRatingEntity rating,
  ) {
    try {
      final ratingDocRef = _firestore
          .collection('events')
          .doc(rating.eventID)
          .collection('participant_ratings')
          .doc('${rating.raterID}_${rating.rateeID}');

      final ratingWithId = rating.copyWith(
        rateeID: ratingDocRef.id,
      );
      final ratingModel = ParticipantRatingModel.fromEntity(ratingWithId);

      return ratingDocRef.set(ratingModel.toFirestore());
    } on Exception catch (e) {
      _logger.error('Failed to add participant rating: $e');
      rethrow;
    }
  }

  @override
  Future<List<ParticipantRatingEntity>> getParticipantRatings(
    Identifier eventId,
  ) {
    return _firestore
        .collection('events')
        .doc(eventId)
        .collection('participant_ratings')
        .get()
        .then(
          (snapshot) => snapshot.docs
              .map(
                (doc) =>
                    ParticipantRatingModel.fromFirestore(doc.data()).toEntity(),
              )
              .toList(),
        );
  }

  @override
  Future<List<ParticipantRatingEntity>> getRatingsByRater(
    Identifier eventId,
    Identifier raterID,
  ) async {
    return _firestore
        .collection('events')
        .doc(eventId)
        .collection('participant_ratings')
        .where('raterID', isEqualTo: raterID)
        .get()
        .then(
          (snapshot) => snapshot.docs
              .map(
                (doc) =>
                    ParticipantRatingModel.fromFirestore(doc.data()).toEntity(),
              )
              .toList(),
        );
  }

  @override
  Future<List<ParticipantRatingEntity>> getRatingsByRatee(
    Identifier eventId,
    Identifier rateeID,
  ) async {
    return _firestore
        .collection('events')
        .doc(eventId)
        .collection('participant_ratings')
        .where('rateeID', isEqualTo: rateeID)
        .get()
        .then(
          (snapshot) => snapshot.docs
              .map(
                (doc) =>
                    ParticipantRatingModel.fromFirestore(doc.data()).toEntity(),
              )
              .toList(),
        );
  }

  @override
  Future<void> updateParticipantRating(
    ParticipantRatingEntity rating,
  ) async {
    try {
      final ratingModel = ParticipantRatingModel.fromEntity(rating);
      await _firestore
          .collection('events')
          .doc(rating.eventID)
          .collection('participant_ratings')
          .doc('${rating.raterID}_${rating.rateeID}')
          .update(ratingModel.toFirestore());
    } on Exception catch (e) {
      _logger.error('Failed to update participant rating: $e');
      rethrow;
    }
  }

  @override
  Future<void> deleteParticipantRating(
    Identifier eventId,
    Identifier raterID,
    Identifier rateeID,
  ) async {
    try {
      await _firestore
          .collection('events')
          .doc(eventId)
          .collection('participant_ratings')
          .doc('${raterID}_$rateeID')
          .delete();
    } on Exception catch (e) {
      _logger.error('Failed to delete participant rating: $e');
      rethrow;
    }
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
