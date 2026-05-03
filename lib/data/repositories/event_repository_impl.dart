import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:outnest/application/get_it_service_locators/get_it_init.dart';
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
import 'package:outnest/domain/services/session_service.dart';

class EventRepositoryImpl implements EventRepository {
  EventRepositoryImpl({
    required FirebaseFirestore firestore,
    required LoggingService logger,
  }) : _firestore = firestore,
       _logger = logger;

  final FirebaseFirestore _firestore;
  final LoggingService _logger;

  // --- CRUD Operations ---

  @override
  Future<void> createEvent(EventEntity event) async {
    try {
      final batch = _firestore.batch();

      // 1. Referanslar
      final docRef = _firestore.collection('events').doc();
      final eventId = docRef.id;

      final userEventLogRef = _firestore
          .collection('users')
          .doc(event.creator.userID)
          .collection('eventLog')
          .doc(eventId);
      final creatorParticipantRef = _firestore
          .collection('events')
          .doc(eventId)
          .collection('participants')
          .doc(event.creator.userID);
      final sensitiveRef = _firestore
          .collection('events')
          .doc(eventId)
          .collection('sensitive')
          .doc('meta');

      // Creator Entity Hazırlığı
      final creatorAsParticipant = CompactUserEntity(
        userID: event.creator.userID,
        username: event.creator.username,
        profileImageUrl: event.creator.profileImageUrl,
        city: null,
        university: event.creator.university,
        nameSurname: null,
        isPrivate: null,
        bio: null,
        accountType: event.creator.accountType,
        communityData: null,
      );

      Geolocation? publicLocation;
      var publicGeohash = '';

      // Eğer haritada gösterilmesin denmişse (false),
      // Location verisini NULL yapıyoruz. Böylece harita render edemez.
      if (event.showOnMap && event.location != null) {
        publicLocation = event.location;
        publicGeohash = event.geohash;
      } else {
        publicLocation = null; // Haritadan silinir
        publicGeohash = ''; // Aramadan silinir
      }

      // --- PUBLIC MODEL (Ana Doküman) ---
      final publicEntity = event.copyWith(
        eventID: eventId,
        participantCount: 1,
        participants: [creatorAsParticipant],

        // Filtrelenmiş verileri basıyoruz:
        location: publicLocation,
        geohash: publicGeohash,
      );

      final publicModel = EventModel.fromEntity(publicEntity);

      // --- SENSITIVE DATA (Yedek/Gerçek Veri) ---
      // Haritada gizlense bile (showOnMap=false), verinin aslı burada durur.
      // İleride detay sayfasında göstermek istersen buradan çekersin.
      final sensitiveData = {
        'realLocation': event.location != null
            ? GeoPoint(event.location!.latitude, event.location!.longitude)
            : null,
        'realAddress': event.address, // Adresi de buraya yedekliyoruz
        'updatedAt': FieldValue.serverTimestamp(),
      };

      // --- BATCH COMMIT ---
      batch
        ..set(docRef, publicModel.toFirestore())
        ..set(sensitiveRef, sensitiveData)
        ..set(creatorParticipantRef, creatorAsParticipant.toMap());

      final userEvent = UserEventEntity(
        eventId: eventId,
        role: EventRoleEnum.creator,
        status: UserEventStatusEnum.upcoming,
        isActive: true,
        updatedAt: DateTime.now(),
        category: event.hobbies.isNotEmpty ? event.hobbies[0] : null,
      );
      batch.set(
        userEventLogRef,
        UserEventModel.fromEntity(userEvent).toFirestore(),
      );

      await batch.commit();
      _logger.info('Event created: $eventId. ShowOnMap: ${event.showOnMap}');
    } catch (e) {
      _logger.error('Failed to create event: $e');
      rethrow;
    }
  }

  @override
  Future<void> updateEvent(String eventId, Map<String, dynamic> changes) async {
    final locationChanged = changes.containsKey('location');

    if (locationChanged) {
      final privateChanges = changes.entries.where(
        (entry) => entry.key == 'location' || entry.key == 'address',
      );

      await _firestore
          .collection('events')
          .doc(eventId)
          .collection('sensitive')
          .doc('meta')
          .update(
            {
              ...Map.fromEntries(privateChanges),
              'updatedAt': FieldValue.serverTimestamp(),
            },
          );
    }

    final publicChanges = Map<String, dynamic>.from(changes)
      ..removeWhere((key, _) {
        return key == 'location' || key == 'address';
      });

    if (publicChanges.isEmpty) {
      // Sadece konum veya adres değişmiş, ana dokümanda güncelleme yapmaya gerek yok
      return;
    }

    try {
      await _firestore.collection('events').doc(eventId).update(publicChanges);
    } catch (e) {
      _logger.error('Failed to update event partial: $e');
      rethrow;
    }
  }

  @override
  Future<void> deleteEvent(Identifier eventId) async {
    try {
      await _firestore.collection('events').doc(eventId).delete();
    } catch (e) {
      _logger.error('Failed to delete event: $e');
      rethrow;
    }
  }

  // --- FETCH & ENRICHMENT ---
  @override
  Future<EventEntity> enrichEventWithDetails(EventEntity event) async {
    try {
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

      return event.copyWith(
        participants: results[0].docs
            .map((d) => CompactUserEntity.fromMap(d.data()))
            .toList(),
        requestPool: results[1].docs
            .map((d) => CompactUserEntity.fromMap(d.data()))
            .toList(),
        rejectedUsers: results[2].docs
            .map((d) => CompactUserEntity.fromMap(d.data()))
            .toList(),
        participantCount: results[0].docs.length,
      );
    } catch (e) {
      _logger.error('Failed to enrich event details for ${event.eventID}: $e');
      return event;
    }
  }

  /// Yardımcı Metod: Yetki kontrolü yapar ve gerekiyorsa hassas veriyi çeker
  @override
  Future<EventEntity> injectSensitiveDataIfAuthorized(
    EventEntity event,
    String? currentUserId,
  ) async {
    // Yetki Kontrolü:
    final isCreator = event.creator.userID == currentUserId;
    // 2. Kullanıcı Katılımcı mı?
    final isParticipant = event.participants.any(
      (p) => p.userID == currentUserId,
    );
    // 3. buluşma Herkese Açık mı? (Kurallardaki showOnMap şartı)
    final isPublicOnMap = event.showOnMap;

    final hasAccess = isCreator || isParticipant || isPublicOnMap;

    if (!hasAccess) return event;

    try {
      final sensitiveDoc = await _firestore
          .collection('events')
          .doc(event.eventID)
          .collection('sensitive')
          .doc('meta') // Kuralda {docId} demiştik, 'meta' olması sorun değil.
          .get();
      if (sensitiveDoc.exists && sensitiveDoc.data() != null) {
        // Model'deki static helper ile veriyi parse et
        final sensitiveData = EventModel.parseSensitiveData(
          sensitiveDoc.data()!,
        );

        // Entity'yi gerçek verilerle güncelle (Merge)
        return event.copyWith(
          address: sensitiveData['address'] as String?,
          location: sensitiveData['location'] as Geolocation?,
        );
      }
    } catch (e) {
      _logger.warn(
        'Sensitive data fetch failed for event ${event.eventID}: $e',
      );
      // Hata olsa bile etkinliğin kısıtlı halini dönmek daha güvenli (Fail-safe)
    }

    return event;
  }

  @override
  Future<List<EventEntity>> getEventsByIds(List<Identifier> eventIds) async {
    if (eventIds.isEmpty) return [];
    try {
      final snapshot = await _firestore
          .collection('events')
          .where('eventID', whereIn: eventIds)
          .get();

      final events = snapshot.docs
          .map((doc) => EventModel.fromFirestore(doc.data()).toEntity())
          .toList();

      return Future.wait(events.map((e) => enrichEventWithDetails(e)));
    } catch (e) {
      _logger.error('Failed to get events by IDs: $e');
      rethrow;
    }
  }

  @override
  Future<EventEntity?> getEvent(Identifier eventId) async {
    try {
      final doc = await _firestore.collection('events').doc(eventId).get();

      if (!doc.exists) return null;

      final eventModel = EventModel.fromFirestore(doc.data()!);
      final eventEntity = eventModel.toEntity();

      final enrichedEvent = await enrichEventWithDetails(eventEntity);
      final finalEvent = await injectSensitiveDataIfAuthorized(
        enrichedEvent,
        getIt<SessionService>().currentUser?.userID,
      );
      return finalEvent;
    } catch (e) {
      _logger.error('Failed to fetch event: $e');
      rethrow;
    }
  }

  @override
  Stream<EventEntity?> getEventStream(Identifier eventId) {
    return _firestore.collection('events').doc(eventId).snapshots().asyncMap((
      snapshot,
    ) async {
      try {
        _logger.debug('🔥 snapshot status: ${snapshot.data()?['status']}');
        if (!snapshot.exists || snapshot.data() == null) return null;
        final eventModel = EventModel.fromFirestore(snapshot.data()!);
        final eventEntity = eventModel.toEntity();
        final enrichedEvent = await enrichEventWithDetails(eventEntity);
        final finalEvent = await injectSensitiveDataIfAuthorized(
          enrichedEvent,
          getIt<SessionService>().currentUser?.userID,
        );
        _logger.debug('✅ emit edilen status: ${finalEvent.status}');
        return finalEvent;
      } catch (e, s) {
        _logger.error('❌ asyncMap HATA: $e\n$s');
        rethrow; // veya return null;
      }
    });
  }

  // --- PARTICIPANTS SUBCOLLECTION (TRIGGER LOGIC) ---

  @override
  Future<void> requestJoin(String eventId, CompactUserEntity user) async {
    try {
      // 1. buluşma sahibini (Creator) bulmalıyız ki onu dürtebilelim.
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
      final hobbies =
          (eventDoc.data()?['hobbies'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [];

      final userEvent = UserEventEntity(
        eventId: eventId,
        role: EventRoleEnum.participant,
        status: UserEventStatusEnum.pending,
        isActive: true,
        updatedAt: DateTime.now(),
        category: hobbies.isNotEmpty ? hobbies[0] : null,
      );

      batch
        ..set(requestPoolRef, user.toMap())
        ..set(
          userEventLogRef,
          UserEventModel.fromEntity(userEvent).toFirestore(),
        );

      await batch.commit();

      // Cache temizlemeye gerek yok çünkü bu metodu çağıran genelde
      // istek atan kişidir, kurucu değil. Ama garanti olsun diye:
    } catch (e) {
      _logger.error('Failed to request join: $e');
      rethrow;
    }
  }

  @override
  Future<void> withdrawJoinRequest(
    String eventId,
    CompactUserEntity user,
  ) async {
    try {
      final eventDoc = await _firestore.collection('events').doc(eventId).get();
      if (!eventDoc.exists) throw Exception('Buluşma bulunamadı');

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

      batch
        ..delete(requestPoolRef)
        ..delete(userEventLogRef);

      await batch.commit();
      _logger.info('Join request withdrawn for event: $eventId');
    } catch (e) {
      _logger.error('Failed to withdraw join request: $e');
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
        if (!eventDoc.exists) throw Exception('buluşma bulunamadı');
        final hobbies =
            (eventDoc.data()?['hobbies'] as List<dynamic>?)
                ?.map((e) => e.toString())
                .toList() ??
            [];

        final currentCount = (eventDoc.data()?['participantCount'] ?? 0) as int;
        const maxParticipants = AppConfig.eventCapacity;
        final creatorId = eventDoc.data()?['creator']?['userID'] as String?;

        if (currentCount >= maxParticipants) {
          throw Exception('buluşma dolu!');
        }

        transaction
          ..set(participantRef, participant.toMap())
          ..delete(requestPoolRef)
          ..update(eventRef, {
            'participantCount': currentCount + 1,
          })
          ..set(userEventLogRef, {
            'status': eventDoc.data()?['status'],
            'category': hobbies.isNotEmpty ? hobbies[0] : null,
            'updatedAt': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));
      });
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
      if (!eventDoc.exists) throw Exception('buluşma bulunamadı');

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

      await batch.commit();
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
        if (!eventDoc.exists) throw Exception('buluşma bulunamadı');

        final currentCount = (eventDoc.data()?['participantCount'] ?? 0) as int;
        final creatorId = eventDoc.data()?['creator']?['userID'] as String?;

        final newParticipantCount = currentCount - 1;

        transaction.delete(participantRef);

        if (newParticipantCount <= 0) {
          transaction.delete(eventRef);
        } else {
          transaction.update(eventRef, {
            'participantCount': newParticipantCount,
          });
        }

        transaction
          ..set(userEventLogRef, {
            'status': UserEventStatusEnum.rejected.toString(),
            'updatedAt': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true))
          ..set(rejectedUsersRef, user.toMap());
      });
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

  @override
  Future<List<CompactUserEntity>> getEventParticipants(String eventId) async {
    try {
      final snapshot = await _firestore
          .collection('events')
          .doc(eventId)
          .collection('participants')
          .get();

      return snapshot.docs
          .map((doc) => CompactUserEntity.fromMap(doc.data()))
          .toList();
    } catch (e) {
      _logger.error('Failed to get event participants: $e');
      rethrow;
    }
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
    // 1. buluşma dolu mu?
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

  @override
  Future<bool> hasSentInvitation(EventEntity event, Identifier user) async {
    try {
      // 1. Yol: 'users' -> {Kullanıcı ID} -> 'notifications'
      // user parametresinin kullanıcının gerçek ID'sini içerdiğinden emin olun.
      final snapshot = await _firestore
          .collection('users')
          .doc(user) // Etkinlik ID değil, hedef kullanıcı ID olmalı
          .collection('notifications')
          .where('type', isEqualTo: 'invite')
          .where('eventID', isEqualTo: event.eventID)
          .limit(1) // Performans için: İlk eşleşmede dur
          .get();

      return snapshot.docs.isNotEmpty;
    } catch (e) {
      _logger.error('Davet kontrolü başarısız: $e');
      return false;
    }
  }

  @override
  Future<void> markEventAsVerified({
    required String eventId,
    required String userId,
  }) async {
    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('eventLog')
          .doc(eventId)
          .update({
            'isVerified': true,
            'verifiedAt': FieldValue.serverTimestamp(),
          });
      _logger.info('Event $eventId marked as verified for user $userId');
    } catch (e) {
      _logger.error('Failed to mark event as verified: $e');
      rethrow;
    }
  }
}
