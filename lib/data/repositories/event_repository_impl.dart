import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:outnest/core/constants/configs/app_config.dart';
import 'package:outnest/core/utils/logging/logging_service.dart';
import 'package:outnest/core/utils/types/enums/event_role_enum.dart';
import 'package:outnest/core/utils/types/enums/user_event_status_enum.dart';
import 'package:outnest/core/utils/types/geolocation/geolocation.dart';
import 'package:outnest/core/utils/types/types.dart';
import 'package:outnest/data/models/event/event_messages_model.dart';
import 'package:outnest/data/models/event/event_model.dart';
import 'package:outnest/data/models/user/user_event_model.dart';
import 'package:outnest/domain/entities/feed/event/event_entity.dart';
import 'package:outnest/domain/entities/feed/event/event_messages_entity.dart';
import 'package:outnest/domain/entities/hobby/hobby_entity.dart';
import 'package:outnest/domain/entities/user/compact_user_entity.dart';
import 'package:outnest/domain/entities/user/user_event_entity.dart';
import 'package:outnest/domain/repositories/event_repository.dart';
import 'package:outnest/domain/services/global_content_cache.dart';

class EventRepositoryImpl implements EventRepository {
  EventRepositoryImpl({
    required FirebaseFirestore firestore,
    required LoggingService logger,
    required GlobalContentCache globalCache,
  }) : _firestore = firestore,
       _logger = logger,
       _globalCache = globalCache;

  final FirebaseFirestore _firestore;
  final LoggingService _logger;
  final GlobalContentCache _globalCache;

  // --- HELPER: TRIGGER CREATOR ---
  /// Bu metod, bir değişiklik olduğunda (katılma, çıkma, reddetme vb.)
  /// Etkinlik sahibinin (Creator) `eventLog` kaydını güncelleyerek
  /// onun ekranındaki Stream'in tetiklenmesini sağlar.
  void _triggerCreatorRefresh(
    Transaction? transaction,
    WriteBatch? batch,
    String creatorId,
    String eventId,
  ) {
    final creatorLogRef = _firestore
        .collection('users')
        .doc(creatorId)
        .collection('eventLog')
        .doc(eventId);

    final data = {'updatedAt': FieldValue.serverTimestamp()};

    if (transaction != null) {
      transaction.update(creatorLogRef, data);
    } else if (batch != null) {
      batch.update(creatorLogRef, data);
    } else {
      // Eğer batch veya transaction yoksa direkt update yap
      creatorLogRef.update(data).catchError((e) {
        _logger.error('Failed to trigger creator refresh: $e');
      });
    }
  }

  // --- CRUD Operations ---

  @override
  Future<void> createEvent(EventEntity event) async {
    try {
      final docRef = _firestore.collection('events').doc();
      final eventId = docRef.id;
      final userEventLogRef = _firestore
          .collection('users')
          .doc(event.creator.userID)
          .collection('eventLog')
          .doc(eventId);

      final userEvent = UserEventEntity(
        eventId: eventId,
        role: EventRoleEnum.creator,
        status: UserEventStatusEnum.upcoming,
        updatedAt: DateTime.now(),
      );

      // Creator'ı hem Subcollection'a hem de Ana Dökümana ekliyoruz.
      final eventWithId = event.copyWith(
        eventID: eventId,
        participantCount: 1,
        participants: [
          CompactUserEntity(
            userID: event.creator.userID,
            username: event.creator.username,
            profileImageUrl: event.creator.profileImageUrl,
            university: event.creator.university,
          ),
        ],
      );

      final eventModel = EventModel.fromEntity(eventWithId);
      final userEventModel = UserEventModel.fromEntity(userEvent);

      final creatorRef = _firestore
          .collection('events')
          .doc(eventId)
          .collection('participants')
          .doc(event.creator.userID);

      final batch = _firestore.batch()
        ..set(docRef, eventModel.toFirestore())
        ..set(creatorRef, event.creator.toMap())
        ..set(userEventLogRef, userEventModel.toFirestore());

      await batch.commit();
      _logger.info('Event created with ID: $eventId');
    } catch (e) {
      _logger.error('Failed to create event: $e');
      rethrow;
    }
  }

  @override
  Future<void> updateEvent(String eventId, Map<String, dynamic> changes) async {
    try {
      await _firestore.collection('events').doc(eventId).update(changes);
      _globalCache.removeEntity(eventId); // Değişiklik sonrası cache temizliği
    } catch (e) {
      _logger.error('Failed to update event partial: $e');
      rethrow;
    }
  }

  @override
  Future<void> deleteEvent(Identifier eventId) async {
    try {
      await _firestore.collection('events').doc(eventId).delete();
      _globalCache.removeEntity(eventId);
    } catch (e) {
      _logger.error('Failed to delete event: $e');
      rethrow;
    }
  }

  // --- FETCH & ENRICHMENT ---

  @override
  Future<EventEntity> enrichEventWithDetails(
    EventEntity event, {
    bool forceRefresh = false,
  }) async {
    // 1. CACHE KONTROLÜ
    if (!forceRefresh) {
      final cachedItem = _globalCache.getEntity(event.eventID);

      if (cachedItem is EventEntity) {
        // Veri tutarlılığını kontrol et (Örn: katılımcı listesi boş mu değil mi?)
        final isDataComplete =
            cachedItem.participants.isNotEmpty ||
            cachedItem.participantCount == 0;

        if (isDataComplete) {
          return cachedItem;
        }
      }
    }

    try {
      // 2. PARALEL VERİ ÇEKME
      final results = await Future.wait([
        _firestore
            .collection('events')
            .doc(event.eventID)
            .collection('participants')
            .get(),
        _firestore
            .collection('events')
            .doc(event.eventID)
            .collection('requestPool')
            .get(),
        _firestore
            .collection('events')
            .doc(event.eventID)
            .collection('rejectedUsers')
            .get(),
      ]);

      // 3. MAPLEME
      final participantsList = results[0].docs
          .map((d) => CompactUserEntity.fromMap(d.data()))
          .toList();

      final requestPoolList = results[1].docs
          .map((d) => CompactUserEntity.fromMap(d.data()))
          .toList();

      final rejectedUsersList = results[2].docs
          .map((d) => CompactUserEntity.fromMap(d.data()))
          .toList();

      // 4. BİRLEŞTİRME
      final fullEvent = event.copyWith(
        participants: participantsList,
        requestPool: requestPoolList,
        rejectedUsers: rejectedUsersList,
        participantCount: participantsList.length,
      );

      // 5. CACHE GÜNCELLEME
      _globalCache.cacheEntity(fullEvent);

      return fullEvent;
    } catch (e) {
      _logger.error('Failed to enrich event details for ${event.eventID}: $e');
      // Hata durumunda elimizdeki eksik veriyi dönüyoruz ki UI çökmesin
      return event;
    }
  }

  @override
  Stream<List<EventEntity>> getEnrichedEventsOfUserStream(Identifier userId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('eventLog')
        .where('status', whereIn: ['upcoming', 'ongoing'])
        .snapshots()
        .asyncMap((snapshot) async {
          if (snapshot.docs.isEmpty) return [];

          final eventIds = snapshot.docs
              .map((doc) => UserEventModel.fromFirestore(doc.data()).eventID)
              .toList();

          // Stream tetiklendiğinde (bizim log güncellememiz sayesinde),
          // Cache'e bakmadan doğrudan Firestore'dan en güncel veriyi çekecek.
          // forceRefresh: true bu işi yapar.
          final enrichedEvents = await getEventsByIds(
            eventIds,
            loadDetails: true,
            forceRefresh: true,
          );
          return enrichedEvents;
        });
  }

  @override
  Future<List<EventEntity>> getEventsByIds(
    List<Identifier> eventIds, {
    bool loadDetails = true,
    bool forceRefresh = false,
  }) async {
    if (eventIds.isEmpty) return Future.value([]);
    try {
      final snapshot = await _firestore
          .collection('events')
          .where('eventID', whereIn: eventIds)
          .get();

      final data = snapshot.docs
          .map((doc) => EventModel.fromFirestore(doc.data()).toEntity())
          .toList();

      if (loadDetails) {
        // Parametreyi aşağıya iletiyoruz
        final enrichedEvents = await Future.wait(
          data.map(
            (event) =>
                enrichEventWithDetails(event, forceRefresh: forceRefresh),
          ),
        );
        return enrichedEvents;
      } else {
        return data;
      }
    } catch (e) {
      _logger.error('Failed to get events by IDs: $e');
      rethrow;
    }
  }

  @override
  Future<EventEntity?> getEvent(
    Identifier eventId, {
    bool loadDetails = true,
  }) async {
    try {
      final doc = await _firestore.collection('events').doc(eventId).get();

      if (!doc.exists) return null;

      final eventModel = EventModel.fromFirestore(doc.data()!);
      final eventEntity = eventModel.toEntity();

      if (!loadDetails) {
        return eventEntity;
      }

      return await enrichEventWithDetails(eventEntity);
    } catch (e) {
      _logger.error('Failed to fetch event: $e');
      rethrow;
    }
  }

  // --- PARTICIPANTS SUBCOLLECTION (TRIGGER LOGIC) ---

  @override
  Future<void> requestJoin(String eventId, CompactUserEntity user) async {
    try {
      // 1. Etkinlik sahibini (Creator) bulmalıyız ki onu dürtebilelim.
      final eventDoc = await _firestore.collection('events').doc(eventId).get();
      if (!eventDoc.exists) throw Exception('Buluşma bulunamadı');

      // Model yapısına göre creator ID path'i
      final creatorId = eventDoc.data()?['creator']?['userID'] as String?;

      final batch = _firestore.batch();

      final requestPoolRef = _firestore
          .collection('events')
          .doc(eventId)
          .collection('requestPool')
          .doc(user.userID);

      final userEventLogRef = _firestore
          .collection('users')
          .doc(user.userID)
          .collection('eventLog')
          .doc(eventId);

      final userEvent = UserEventEntity(
        eventId: eventId,
        role: EventRoleEnum.participant,
        status: UserEventStatusEnum.pending,
        updatedAt: DateTime.now(),
      );

      batch
        ..set(requestPoolRef, user.toMap())
        ..set(
          userEventLogRef,
          UserEventModel.fromEntity(userEvent).toFirestore(),
        );

      // --- TRIGGER ---
      // Kurucu, yeni isteği anında görmeli (Kırmızı nokta vs.)
      if (creatorId != null) {
        _triggerCreatorRefresh(null, batch, creatorId, eventId);
      }

      await batch.commit();

      // Cache temizlemeye gerek yok çünkü bu metodu çağıran genelde
      // istek atan kişidir, kurucu değil. Ama garanti olsun diye:
      _globalCache.removeEntity(eventId);
    } catch (e) {
      _logger.error('Failed to request join: $e');
      rethrow;
    }
  }

  @override
  Future<void> acceptParticipant(String eventId, CompactUserEntity user) async {
    try {
      final eventRef = _firestore.collection('events').doc(eventId);
      final userEventLogRef = _firestore
          .collection('users')
          .doc(user.userID)
          .collection('eventLog')
          .doc(eventId);

      final participantRef = eventRef
          .collection('participants')
          .doc(user.userID);
      final requestPoolRef = eventRef
          .collection('requestPool')
          .doc(user.userID);

      final participant = EventParticipantEntity(
        userID: user.userID,
        username: user.username,
        profileImageUrl: user.profileImageUrl,
        role: EventRoleEnum.participant,
        eventScore: 0,
        university: user.university,
      );

      await _firestore.runTransaction((transaction) async {
        final eventDoc = await transaction.get(eventRef);
        if (!eventDoc.exists) throw Exception('Etkinlik bulunamadı');

        final currentCount = (eventDoc.data()?['participantCount'] ?? 0) as int;
        const maxParticipants = AppConfig.eventCapacity;
        final creatorId = eventDoc.data()?['creator']?['userID'] as String?;

        if (currentCount >= maxParticipants) {
          throw Exception('Buluşma dolu!');
        }

        transaction
          ..set(participantRef, participant.toMap())
          ..delete(requestPoolRef)
          ..update(eventRef, {
            'participantCount': currentCount + 1,
          })
          ..set(userEventLogRef, {
            'status': eventDoc.data()?['status'],
            'updatedAt': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));

        // --- TRIGGER ---
        // Kurucunun listesi güncellensin
        if (creatorId != null) {
          _triggerCreatorRefresh(transaction, null, creatorId, eventId);
        }
      });

      // --- CACHE TEMİZLİĞİ ---
      _globalCache.removeEntity(eventId);
    } catch (e) {
      _logger.error('Failed to accept participant: $e');
      rethrow;
    }
  }

  @override
  Future<void> rejectRequest(String eventId, CompactUserEntity user) async {
    try {
      // Önce Creator ID'yi bulmak için eventi çekiyoruz.
      final eventDoc = await _firestore.collection('events').doc(eventId).get();
      if (!eventDoc.exists) throw Exception('Buluşma bulunamadı');

      final creatorId = eventDoc.data()?['creator']?['userID'] as String?;

      final eventRef = _firestore.collection('events').doc(eventId);
      final requestPoolRef = eventRef
          .collection('requestPool')
          .doc(user.userID);
      final rejectedUsersRef = eventRef
          .collection('rejectedUsers')
          .doc(user.userID);

      final userEventLogRef = _firestore
          .collection('users')
          .doc(user.userID)
          .collection('eventLog')
          .doc(eventId);

      final batch = _firestore.batch()
        ..delete(requestPoolRef)
        ..set(rejectedUsersRef, user.toMap())
        ..set(userEventLogRef, {
          'status': UserEventStatusEnum.rejected.toString(),
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));

      // --- TRIGGER ---
      // Kurucu, isteği reddettiğinde listeden düştüğünü anında görmeli
      if (creatorId != null) {
        _triggerCreatorRefresh(null, batch, creatorId, eventId);
      }

      await batch.commit();

      // --- CACHE TEMİZLİĞİ ---
      _globalCache.removeEntity(eventId);
    } catch (e) {
      _logger.error('Failed to reject request: $e');
      rethrow;
    }
  }

  @override
  Future<void> removeParticipant(
    Identifier eventId,
    CompactUserEntity user,
  ) async {
    try {
      final eventRef = _firestore.collection('events').doc(eventId);
      final participantRef = eventRef
          .collection('participants')
          .doc(user.userID);
      final rejectedUsersRef = eventRef
          .collection('rejectedUsers')
          .doc(user.userID);

      final userEventLogRef = _firestore
          .collection('users')
          .doc(user.userID)
          .collection('eventLog')
          .doc(eventId);

      await _firestore.runTransaction((transaction) async {
        final eventDoc = await transaction.get(eventRef);
        if (!eventDoc.exists) throw Exception('Etkinlik bulunamadı');

        final currentCount = (eventDoc.data()?['participantCount'] ?? 0) as int;
        final creatorId = eventDoc.data()?['creator']?['userID'] as String?;

        transaction
          ..delete(participantRef)
          ..update(eventRef, {
            'participantCount': currentCount > 0 ? currentCount - 1 : 0,
          })
          ..set(userEventLogRef, {
            'status': UserEventStatusEnum.rejected.toString(),
            'updatedAt': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true))
          ..set(rejectedUsersRef, user.toMap());

        // --- TRIGGER ---
        // Kurucu, katılımcıyı attığında listeden düştüğünü görmeli
        if (creatorId != null) {
          _triggerCreatorRefresh(transaction, null, creatorId, eventId);
        }
      });

      // --- CACHE TEMİZLİĞİ ---
      _globalCache.removeEntity(eventId);
    } catch (e) {
      _logger.error('Failed to remove participant: $e');
      rethrow;
    }
  }

  @override
  Future<void> updateParticipant(
    String eventId,
    EventParticipantEntity newParticipantData,
  ) async {
    throw UnimplementedError();
  }

  // --- MESSAGES SUBCOLLECTION ---

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
    } catch (e) {
      _logger.error('Failed to add message: $e');
      rethrow;
    }
  }

  @override
  Future<List<EventMessagesEntity>> getMessages(Identifier eventId) async {
    try {
      final snapshot = await _firestore
          .collection('events')
          .doc(eventId)
          .collection('messages')
          .orderBy('timestamp', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => EventMessagesModel.fromFirestore(doc.data()).toEntity())
          .toList();
    } catch (e) {
      _logger.error('Failed to get messages: $e');
      rethrow;
    }
  }

  @override
  Future<List<EventMessagesEntity>> getMessagesByUser(
    Identifier eventId,
    Identifier userId,
  ) async {
    try {
      final snapshot = await _firestore
          .collection('events')
          .doc(eventId)
          .collection('messages')
          .where('senderId', isEqualTo: userId)
          .get();

      return snapshot.docs
          .map((doc) => EventMessagesModel.fromFirestore(doc.data()).toEntity())
          .toList();
    } catch (e) {
      _logger.error('Failed to get messages by user: $e');
      rethrow;
    }
  }

  @override
  Future<void> deleteMessage(Identifier eventId, Identifier messageId) {
    try {
      return _firestore
          .collection('events')
          .doc(eventId)
          .collection('messages')
          .doc(messageId)
          .delete();
    } catch (e) {
      _logger.error('Failed to delete message: $e');
      rethrow;
    }
  }

  // --- QUERY & SEARCH ---

  @override
  bool canUserJoinEvent(
    EventEntity event,
    Identifier userID,
  ) {
    // 1. Etkinlik dolu mu?
    if (event.participantCount >= AppConfig.eventCapacity) {
      return false;
    }

    // 2. Kullanıcı zaten katılımcı mı?
    final isAlreadyParticipant = event.participants.any(
      (participant) => participant.userID == userID,
    );
    if (isAlreadyParticipant) {
      return false;
    }

    // 3. Kullanıcı reddedilmiş mi?
    final isRejected = event.rejectedUsers.any(
      (rejectedUser) => rejectedUser.userID == userID,
    );
    if (isRejected) {
      return false;
    }

    // 4. Kullanıcı zaten istek göndermiş mi?
    final isInRequestPool = event.requestPool.any(
      (requestUser) => requestUser.userID == userID,
    );

    if (isInRequestPool) {
      return false;
    }

    return true;
  }

  @override
  Future<List<EventEntity>> getAllEvents() async {
    try {
      final querySnapshot = await _firestore.collection('events').get();
      return querySnapshot.docs
          .map((doc) => EventModel.fromFirestore(doc.data()).toEntity())
          .toList();
    } catch (e) {
      _logger.error('Failed to get all events: $e');
      rethrow;
    }
  }

  @override
  Future<List<EventEntity>> searchEventsByTitle(String title) async {
    try {
      final querySnapshot = await _firestore
          .collection('events')
          .where('name', isEqualTo: title)
          .get();

      return querySnapshot.docs
          .map((doc) => EventModel.fromFirestore(doc.data()).toEntity())
          .toList();
    } catch (e) {
      _logger.error('Failed to search events by title: $e');
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
  Future<List<EventEntity>> getEventsByHobby(List<HobbyEntity> categories) {
    throw UnimplementedError();
  }

  @override
  Stream<List<UserEventEntity>> getUserEventsStream(Identifier userId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('eventLog')
        .where('status', whereIn: ['upcoming', 'ongoing', 'pending'])
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map(
                (doc) => UserEventModel.fromFirestore(doc.data()).toEntity(),
              )
              .toList(),
        )
        .handleError((e) {
          _logger.error('Error in getUserEventsStream: $e');
          // Stream hatalarında boş liste dönmek veya hatayı propagate etmek
          // stratejine bağlıdır. Burada hatayı fırlatıyoruz.
          throw e as Exception;
        });
  }
}
