import 'package:bulusalim/domain/entities/notification/follow_notification_entity.dart'; // <--- 1. YENİ ENTITY IMPORT
import 'package:bulusalim/domain/entities/notification/notification_entity.dart';
import 'package:bulusalim/domain/repositories/inbox_repository.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

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
  Stream<int> getUnreadCountStream() {
    if (_userId.isEmpty) return Stream.value(0);

    return _firestore
        .collection('users')
        .doc(_userId)
        .collection('notifications')
        .where('isRead', isEqualTo: false)
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  @override
  Future<void> markAsRead(String notificationId) async {
    if (_userId.isEmpty) return;
    await _firestore
        .collection('users')
        .doc(_userId)
        .collection('notifications')
        .doc(notificationId)
        .update({'isRead': true});
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
      avatarUrl: (data['avatarUrl'] as String?) ?? 'https://picsum.photos/200',
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
          (data['profileUrl'] as String?) ?? 'https://picsum.photos/200',
      status: status,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}
