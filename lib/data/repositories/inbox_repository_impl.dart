import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:outnest/application/get_it_service_locators/get_it_init.dart';
import 'package:outnest/domain/entities/notification/follow_notification_entity.dart'; // <--- 1. YENİ ENTITY IMPORT
import 'package:outnest/domain/entities/notification/notification_entity.dart';
import 'package:outnest/domain/repositories/inbox_repository.dart';
import 'package:outnest/domain/services/file_service.dart';
import 'package:outnest/domain/services/persistance_service.dart';

class InboxRepositoryImpl implements InboxRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String get _userId => _auth.currentUser?.uid ?? '';

  String get _lastSeenFollowRequestIdKey => 'lastSeenFollowRequestId_$_userId';
  String get _seenFollowRequestStatesKey => 'seenFollowRequestStates_$_userId';

  DateTime _extractFollowTimestamp(Map<String, dynamic> data) {
    return (data['updatedAt'] as Timestamp?)?.toDate() ??
        (data['createdAt'] as Timestamp?)?.toDate() ??
        DateTime.fromMillisecondsSinceEpoch(0);
  }

  // 1. GENEL BİLDİRİMLER

  @override
  Stream<List<NotificationEntity>> getNotificationsStream() {
    if (_userId.isEmpty) return Stream.value([]);

    return _firestore
        .collection('users')
        .doc(_userId)
        .collection('notifications')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            final data = doc.data();
            return _mapFirestoreToEntity(doc.id, data);
          }).toList();
        });
  }

  @override
  Future<void> markAllNotificationsRead() async {
    if (_userId.isEmpty) return;

    final notificationsRef = _firestore
        .collection('users')
        .doc(_userId)
        .collection('notifications');

    final snapshot = await notificationsRef.get();
    if (snapshot.docs.isEmpty) return;

    final batch = _firestore.batch();
    var hasUpdates = false;

    for (final doc in snapshot.docs) {
      final data = doc.data();
      final isRead = (data['isRead'] as bool?) ?? false;
      if (isRead) continue;

      batch.update(doc.reference, {'isRead': true});
      hasUpdates = true;
    }

    if (hasUpdates) {
      await batch.commit();
    }
  }

  // 2. TAKİP İSTEKLERİ
  @override
  Stream<List<FollowNotificationEntity>> getFollowRequestsStream() {
    if (_userId.isEmpty) return Stream.value([]);

    //todo: add limit and pagination if needed, also consider caching if this becomes a performance issue
    return _firestore
        .collection('users')
        .doc(_userId)
        .collection('followRequests')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            final data = doc.data();
            return _mapFirestoreToFollowEntity(doc.id, data);
          }).toList();
        });
  }

  @override
  Future<bool> hasUnreadFollowRequest() async {
    if (_userId.isEmpty) return false;

    final persistenceService = getIt<PersistanceService>();
    final savedState = await persistenceService.getJson(
      _seenFollowRequestStatesKey,
    );
    final seenStates = <String, int>{};
    final rawStates = savedState?['states'];
    if (rawStates is Map) {
      for (final entry in rawStates.entries) {
        final key = entry.key.toString();
        final value = entry.value;
        if (value is int) {
          seenStates[key] = value;
        } else if (value is num) {
          seenStates[key] = value.toInt();
        }
      }
    }

    print(
      '[REPO] hasUnreadFollowRequest: saved ${seenStates.length} seen states',
    );

    final snapshot = await _firestore
        .collection('users')
        .doc(_userId)
        .collection('followRequests')
        .get();

    print(
      '[REPO] hasUnreadFollowRequest: Firestore query returned ${snapshot.docs.length} docs',
    );

    if (snapshot.docs.isEmpty) {
      print('[REPO] hasUnreadFollowRequest: empty, returning false');
      return false;
    }

    for (final doc in snapshot.docs) {
      final currentTimestamp = _extractFollowTimestamp(doc.data());
      final currentMillis = currentTimestamp.millisecondsSinceEpoch;
      final seenMillis = seenStates[doc.id];
      final isNew = seenMillis == null || currentMillis > seenMillis;
      print(
        '[REPO] hasUnreadFollowRequest: doc ${doc.id} -> currentMillis=$currentMillis seenMillis=$seenMillis isNew=$isNew',
      );
      if (isNew) {
        print(
          '[REPO] hasUnreadFollowRequest: found unread doc ${doc.id}, returning true',
        );
        return true;
      }
    }

    print('[REPO] hasUnreadFollowRequest: all docs seen, returning false');
    return false;
  }

  @override
  Future<void> markFollowRequestsAsSeen(String followRequestId) async {
    if (_userId.isEmpty) return;
    try {
      print('[REPO] markFollowRequestsAsSeen START for $followRequestId');
      final persistenceService = getIt<PersistanceService>();
      final snapshot = await _firestore
          .collection('users')
          .doc(_userId)
          .collection('followRequests')
          .get();

      print(
        '[REPO] markFollowRequestsAsSeen: found ${snapshot.docs.length} docs to mark',
      );

      final seenStates = <String, int>{};
      for (final doc in snapshot.docs) {
        final timestamp = _extractFollowTimestamp(
          doc.data(),
        ).millisecondsSinceEpoch;
        seenStates[doc.id] = timestamp;
        print(
          '[REPO] markFollowRequestsAsSeen: marked ${doc.id} -> $timestamp',
        );
      }

      await persistenceService.saveString(
        _lastSeenFollowRequestIdKey,
        followRequestId,
      );
      await persistenceService.saveJson(
        _seenFollowRequestStatesKey,
        {
          'states': seenStates,
        },
      );

      print(
        "[REPO] markFollowRequestsAsSeen COMPLETE: saved ${seenStates.length} states",
      );
    } catch (e) {
      print("Takip isteği güncellenirken hata oluştu: $e");
    }
  }

  // MAPPERS
  // Mapper 1: Genel Bildirimler
  NotificationEntity _mapFirestoreToEntity(
    String id,
    Map<String, dynamic> data,
  ) {
    final rawType = (data['type'] as String?) ?? '';
    final resolvedEventId =
        (data['eventId'] as String?) ?? (data['eventID'] as String?);
    final actorUserId =
        (data['actorUserId'] as String?) ??
        (data['userId'] as String?) ??
        (data['userID'] as String?) ??
        (data['senderId'] as String?) ??
        (data['fromUserId'] as String?);

    NotificationType type;

    switch (rawType) {
      case 'join':
        type = NotificationType.join;
      case 'invite':
        type = NotificationType.invite;
      case 'cancel':
        type = NotificationType.cancel;
      case 'updateTime':
        type = NotificationType.updateTime;
      case 'updateLocation':
        type = NotificationType.updateLocation;
      case 'warning':
        type = NotificationType.warning;
      case 'tag':
        type = NotificationType.tag;
      case 'badgeWin':
        type = NotificationType.badgeWin;
      case 'badgeProgress':
        type = NotificationType.badgeProgress;
      case 'participants':
        type = NotificationType.participants;
      case 'left':
        type = NotificationType.left;
      case 'timeEnding':
        type = NotificationType.timeEnding;
      case 'created':
        type = NotificationType.created;
      case 'startingSoon':
        type = NotificationType.startingSoon;
      case 'earlyStart':
        type = NotificationType.earlyStart;
      default:
        type = NotificationType.join;
    }

    return NotificationEntity(
      type: type,
      title: (data['title'] as String?) ?? '',
      message: (data['message'] as String?) ?? (data['body'] as String?) ?? '',
      actionText: data['actionText'] as String?,
      profileImageUrl:
          (data['profileImageUrl'] as String?) ??
          FileService.defaultProfileImageUrl(),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isRead: (data['isRead'] as bool?) ?? false,
      eventId: resolvedEventId,
      rawType: rawType,
      actorUserId: actorUserId,
    );
  }

  // Mapper 2: Takip İstekleri
  FollowNotificationEntity _mapFirestoreToFollowEntity(
    String id,
    Map<String, dynamic> data,
  ) {
    final timestamp = _extractFollowTimestamp(data);

    return FollowNotificationEntity(
      userID: id,
      username: (data['username'] as String?) ?? 'Kullanıcı',
      profileImageUrl:
          (data['profileImageUrl'] as String?) ??
          FileService.defaultProfileImageUrl(),
      createdAt: timestamp,
    );
  }
}
