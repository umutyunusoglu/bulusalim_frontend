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
        break;
      case 'invite':
        type = NotificationType.invite;
        break;
      case 'cancel':
        type = NotificationType.cancel;
        break;
      case 'updateTime':
        type = NotificationType.updateTime;
        break;
      case 'updateLocation':
        type = NotificationType.updateLocation;
        break;
      case 'warning':
        type = NotificationType.warning;
        break;
      case 'tag':
        type = NotificationType.tag;
        break;
      case 'badgeWin':
        type = NotificationType.badgeWin;
        break;
      case 'badgeProgress':
        type = NotificationType.badgeProgress;
        break;
      case 'participants':
        type = NotificationType.participants;
        break;
      case 'left':
        type = NotificationType.left;
        break;
      case 'timeEnding':
        type = NotificationType.timeEnding;
        break;
      case 'created':
        type = NotificationType.created;
        break;
      case 'startingSoon':
        type = NotificationType.startingSoon;
        break;
      case 'earlyStart':
        type = NotificationType.earlyStart;
        break;
      default:
        type = NotificationType.join;
    }

    return NotificationEntity(
      id: id,
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
        break;
      case 'sent':
        status = FollowStatus.sent;
        break;
      case 'pending':
        status = FollowStatus.pending;
        break;
      default:
        status = FollowStatus.none;
    }

    return FollowNotificationEntity(
      userID: id,
      username: (data['username'] as String?) ?? 'Kullanıcı',
      profileUrl:
          (data['profileUrl'] as String?) ?? 'https://picsum.photos/200',
      message: (data['message'] as String?) ?? 'seni takip etmek istiyor.',
      status: status,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}
