import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:outnest/application/get_it_service_locators/get_it_init.dart';
import 'package:outnest/data/models/post/post_model.dart';
import 'package:outnest/domain/entities/notification/follow_notification_entity.dart'; // <--- 1. YENİ ENTITY IMPORT
import 'package:outnest/domain/entities/notification/notification_entity.dart';
import 'package:outnest/domain/repositories/inbox_repository.dart';
import 'package:outnest/domain/services/file_service.dart';
import 'package:outnest/domain/services/persistance_service.dart';

class InboxRepositoryImpl implements InboxRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String get _userId => _auth.currentUser?.uid ?? '';

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

  // 2. TAKİP İSTEKLERİ
  @override
  Stream<List<FollowNotificationEntity>> getFollowRequestsStream() {
    if (_userId.isEmpty) return Stream.value([]);

    //todo: add limit and pagination if needed, also consider caching if this becomes a performance issue
    return _firestore
        .collection('users')
        .doc(_userId)
        .collection('followNotifications')
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

    // 1. Cihaza kaydedilmiş son ID'yi al
    final lastSavedId = await persistenceService.getString(
      'lastFollowRequestId_$_userId',
    );

    final snapshot = await _firestore
        .collection('users')
        .doc(_userId)
        .collection('followNotifications')
        .orderBy('createdAt', descending: true)
        .limit(1)
        .get();

    if (snapshot.docs.isEmpty) {
      return false;
    }

    final latestIdFromFirestore = snapshot.docs.first.id;

    if (lastSavedId == null) {
      await persistenceService.saveString(
        'lastFollowRequestId_$_userId',
        latestIdFromFirestore,
      );
      return true;
    }

    // Eğer cihazdaki ID, Firestore'dakinden farklıysa yeni bir şeyler gelmiş demektir
    if (lastSavedId != latestIdFromFirestore) {
      return true;
    }

    return false;
  }

  @override
  Future<void> updateFollowNotificationRead(String notificationId) async {
    try {
      final persistenceService = getIt<PersistanceService>();
      await persistenceService.saveString(
        'lastFollowRequestId',
        notificationId,
      );

      print("Bildirim okundu olarak işaretlendi: $notificationId");
    } catch (e) {
      // Hata yönetimi: Loglama yapabilirsin
      print("Bildirim güncellenirken hata oluştu: $e");
    }
  }

  // MAPPERS
  // Mapper 1: Genel Bildirimler
  NotificationEntity _mapFirestoreToEntity(
    String id,
    Map<String, dynamic> data,
  ) {
    NotificationType type;

    switch (data['type']) {
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
      eventId: data['eventId'] as String?,
    );
  }

  // Mapper 2: Takip İstekleri
  FollowNotificationEntity _mapFirestoreToFollowEntity(
    String id,
    Map<String, dynamic> data,
  ) {
    FollowStatus status;

    // Firestore'daki string'i Enum'a çeviriyoruz
    switch (data['status']) {
      case 'following':
        status = FollowStatus.following;
      case 'sent':
        status = FollowStatus.sent;
      case 'pending':
        status = FollowStatus.pending;
      default:
        status = FollowStatus.none;
    }

    return FollowNotificationEntity(
      userID: id,
      username: (data['username'] as String?) ?? 'Kullanıcı',
      profileImageUrl:
          (data['profileImageUrl'] as String?) ??
          FileService.defaultProfileImageUrl(),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}
