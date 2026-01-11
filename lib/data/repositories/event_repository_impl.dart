import 'package:bulusalim/core/constants/configs/app_config.dart';
import 'package:bulusalim/core/utils/logging/logging_service.dart';
import 'package:bulusalim/core/utils/types/enums/event_role_enum.dart';
import 'package:bulusalim/core/utils/types/enums/event_status_enum.dart';
import 'package:bulusalim/core/utils/types/enums/user_event_status_enum.dart';
import 'package:bulusalim/core/utils/types/geolocation/geolocation.dart';
import 'package:bulusalim/core/utils/types/types.dart';
import 'package:bulusalim/data/models/event/event_messages_model.dart';
import 'package:bulusalim/data/models/event/event_model.dart';
import 'package:bulusalim/data/models/user/user_event_model.dart';
import 'package:bulusalim/domain/entities/feed/event/event_entity.dart';
import 'package:bulusalim/domain/entities/feed/event/event_messages_entity.dart';
import 'package:bulusalim/domain/entities/hobby/hobby_entity.dart';
import 'package:bulusalim/domain/entities/user/compact_user_entity.dart';
import 'package:bulusalim/domain/entities/user/user_event_entity.dart';
import 'package:bulusalim/domain/repositories/event_repository.dart';
import 'package:bulusalim/domain/services/global_content_cache.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

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
        status: UserEventStatusEnum.cancelled,
        updatedAt: DateTime.now(),
      );

      // Creator'ı hem Subcollection'a hem de Ana Dökümana (Feed için) ekliyoruz.
      final eventWithId = event.copyWith(
        eventID: eventId,
        participantCount: 1,
        participants: [
          CompactUserEntity(
            userID: event.creator.userID,
            username: event.creator.username,
            profileImageUrl: event.creator.profileImageUrl,
          ),
        ], // DÜZELTME: Creator listeye eklendi
      );

      final eventModel = EventModel.fromEntity(eventWithId);
      final userEventModel = UserEventModel.fromEntity(userEvent);

      final creatorRef = _firestore
          .collection('events')
          .doc(eventId)
          .collection('participants')
          .doc(event.creator.userID);

      final batch = _firestore.batch()
        // 1. Ana Döküman (İçinde participants array var)
        ..set(docRef, eventModel.toFirestore())
        // 2. Subcollection (Yedek ve Detaylı yönetim için)
        ..set(creatorRef, event.creator.toMap())
        // 3. Kullanıcının event log'una ekleme
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
    } catch (e) {
      _logger.error('Failed to update event partial: $e');
      rethrow;
    }
  }

  @override
  Future<void> deleteEvent(Identifier eventId) async {
    try {
      // Subcollection'lar parent silindiğinde otomatik silinmez (Firestore özelliği).
      // Cloud Function ile temizlenmesi önerilir. Burada sadece parent'ı siliyoruz.
      await _firestore.collection('events').doc(eventId).delete();
    } on Exception catch (e) {
      _logger.error('Failed to delete event::$e');
      rethrow;
    }
  }

  @override
  Future<EventEntity> enrichEventWithDetails(
    EventEntity event, {
    bool forceRefresh = false,
  }) async {
    // 1. CACHE KONTROLÜ
    // Eğer zorla yenileme istenmemişse cache'e bak.
    if (!forceRefresh) {
      final cachedItem = _globalCache.getEntity(event.eventID);

      // Cache'de veri varsa VE bu veri EventEntity türündeyse
      if (cachedItem is EventEntity) {
        // "Veri Tam mı?" kontrolü:
        // Eğer katılımcı listesi doluysa VEYA katılımcı sayısı 0 ise (kimse yok demektir)
        // veriyi tam kabul edip cache'den dönüyoruz. Firestore'a gitmiyoruz.
        final bool isDataComplete =
            cachedItem.participants.isNotEmpty ||
            cachedItem.participantCount == 0;

        if (isDataComplete) {
          return cachedItem;
        }
      }
    }

    try {
      // 2. PARALEL VERİ ÇEKME (Subcollections Only)
      // Ana dökümanı çekmiyoruz, sadece dinamik listeleri çekiyoruz.
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

      // 3. MAPLEME İŞLEMLERİ
      final participantsList = results[0].docs
          .map((d) => CompactUserEntity.fromMap(d.data()))
          .toList();

      final requestPoolList = results[1].docs
          .map((d) => CompactUserEntity.fromMap(d.data()))
          .toList();

      final rejectedUsersList = results[2].docs
          .map((d) => CompactUserEntity.fromMap(d.data()))
          .toList();

      // 4. ENTITY BİRLEŞTİRME (Merging)
      // Feed'den gelen ana veri (event) ile buradan gelen listeleri birleştiriyoruz.
      final fullEvent = event.copyWith(
        participants: participantsList,
        requestPool: requestPoolList,
        rejectedUsers: rejectedUsersList,
        // Feed'deki sayı eski kalmış olabilir, listeye güvenip sayıyı güncelliyoruz.
        participantCount: participantsList.length,
      );

      // 5. CACHE GÜNCELLEME
      // Bir sonraki istekte tekrar çekmemek için full halini cache'e yazıyoruz.
      _globalCache.cacheEntity(fullEvent);

      return fullEvent;
    } catch (e) {
      _logger.error('Failed to enrich event details for ${event.eventID}: $e');
      // Hata durumunda akışı bozmamak için elimizdeki (yarım) veriyi dönüyoruz.
      // Kullanıcı detayları göremese de event'i görür.
      return event;
    }
  }

  @override
  // loadDetails: true -> Full (3 liste dahil)
  // loadDetails: false -> Light (Sadece ana döküman)
  Future<EventEntity?> getEvent(
    Identifier eventId, {
    bool loadDetails = true,
  }) async {
    try {
      // 1. Ana dokümanı çek
      final doc = await _firestore.collection('events').doc(eventId).get();

      if (!doc.exists) return null;

      final eventModel = EventModel.fromFirestore(doc.data()!);
      final eventEntity = eventModel.toEntity();

      // 2. Eğer detay istenmiyorsa direkt döndür (Light Variant)
      if (!loadDetails) {
        return eventEntity;
      }

      // 3. Detay isteniyorsa helper'ı kullan (Full Variant)
      return await enrichEventWithDetails(eventEntity);
    } on Exception catch (e) {
      _logger.error('Failed to fetch event: $e');
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
        .orderBy('timestamp', descending: true)
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

  // --- PARTICIPANTS SUBCOLLECTION (Smart Logic) ---
  @override
  Future<void> requestJoin(String eventId, CompactUserEntity user) async {
    final batch = _firestore.batch();

    // 2. Referansları hazırla
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

    final userEventModel = UserEventModel.fromEntity(userEvent);

    batch
      ..set(requestPoolRef, user.toMap())
      ..set(userEventLogRef, userEventModel.toFirestore());

    await batch.commit();
  }

  @override
  Future<void> acceptParticipant(
    String eventId,
    CompactUserEntity user,
  ) async {
    final eventRef = _firestore.collection('events').doc(eventId);
    final userEventLogRef = _firestore
        .collection('users')
        .doc(user.userID)
        .collection('eventLog')
        .doc(eventId);

    final participantRef = eventRef.collection('participants').doc(user.userID);
    final requestPoolRef = eventRef.collection('requestPool').doc(user.userID);
    // 1. Katılımcıyı Participants'a Ekle

    final participant = EventParticipantEntity(
      userID: user.userID,
      username: user.username,
      profileImageUrl: user.profileImageUrl,
      role: EventRoleEnum.participant,
      eventScore: 0,
    );

    await _firestore.runTransaction((transaction) async {
      // 1. Önce Etkinliği Oku (Kilitler)
      final eventDoc = await transaction.get(eventRef);
      if (!eventDoc.exists) throw Exception('Etkinlik bulunamadı');

      final currentCount = (eventDoc.data()?['participantCount'] ?? 0) as int;
      const maxParticipants = AppConfig.eventCapacity;

      // 2. Kontenjan Kontrolü
      if (currentCount >= maxParticipants) {
        throw Exception('Etkinlik dolu!');
      }

      // 3. Yazma İşlemleri (Batch ile aynı mantık)
      transaction
        ..set(participantRef, participant.toMap())
        ..delete(requestPoolRef)
        ..update(eventRef, {
          'participantCount':
              currentCount +
              1, // increment yerine manuel artırabiliriz çünkü okuduk
        })
        ..set(userEventLogRef, {
          'status': eventDoc
              .data()?['status'], // Güncel statüyü içeriden alıyoruz
          'lastUpdated': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
    });
  }

  @override
  Future<void> rejectRequest(String eventId, CompactUserEntity user) async {
    //TODO: Implement rejectRequest

    final eventRef = _firestore.collection('events').doc(eventId);
    final requestPoolRef = eventRef.collection('requestPool').doc(user.userID);
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
        'lastUpdated': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    await batch.commit();
  }

  @override
  Future<void> updateParticipant(
    String eventId,
    EventParticipantEntity newParticipantData,
  ) async {
    throw UnimplementedError();
  }

  @override
  Future<void> removeParticipant(
    Identifier eventId,
    CompactUserEntity user,
  ) async {
    final eventRef = _firestore.collection('events').doc(eventId);

    final participantRef = eventRef.collection('participants').doc(user.userID);
    final userEventLogRef = _firestore
        .collection('users')
        .doc(user.userID)
        .collection('eventLog')
        .doc(eventId);

    final rejectedUsersRef = eventRef
        .collection('rejectedUsers')
        .doc(user.userID);
    await _firestore.runTransaction((transaction) async {
      final eventDoc = await transaction.get(eventRef);
      if (!eventDoc.exists) throw Exception('Etkinlik bulunamadı');
      final currentCount = (eventDoc.data()?['participantCount'] ?? 0) as int;

      transaction
        ..delete(participantRef)
        ..update(eventRef, {
          'participantCount': currentCount > 0 ? currentCount - 1 : 0,
        })
        ..set(userEventLogRef, {
          'status': UserEventStatusEnum.rejected.toString(),
          'lastUpdated': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true))
        ..set(rejectedUsersRef, user.toMap());
    });
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

    // Tüm kontrolleri geçtiyse katılabilir
    return true;
  }

  @override
  Future<List<EventEntity>> getAllEvents() async {
    try {
      // Feed ekranı için sadece ana dökümanları çekiyoruz.
      // Subcollection çekilmediği için Entity'deki 'participants' listesi boş gelir.
      // Ancak 'participantCount' alanı dolu ve doğrudur.
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
          .where('name', isEqualTo: title)
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
  Future<List<EventEntity>> getEventsByIds(
    List<Identifier> eventIds, {
    bool loadDetails = true,
  }) async {
    if (eventIds.isEmpty) return Future.value([]);
    try {
      final data = await _firestore
          .collection('events')
          .where('eventID', whereIn: eventIds)
          .get()
          .then(
            (snapshot) => snapshot.docs
                .map((doc) => EventModel.fromFirestore(doc.data()).toEntity())
                .toList(),
          );
      if (loadDetails) {
        final enrichedEvents = await Future.wait(
          data.map((event) => enrichEventWithDetails(event)),
        );
        return enrichedEvents;
      } else {
        return data;
      }
    } on Exception catch (e) {
      _logger.error('Failed to get events by IDs: $e');
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
}
