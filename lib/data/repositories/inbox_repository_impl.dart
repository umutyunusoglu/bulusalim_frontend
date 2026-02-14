import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart' as firebase_storage;
import 'package:outnest/domain/entities/notification/follow_notification_entity.dart';
import 'package:outnest/domain/entities/notification/notification_entity.dart';
import 'package:outnest/domain/repositories/inbox_repository.dart';
import 'package:outnest/domain/services/file_service.dart';

class InboxRepositoryImpl implements InboxRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Basit in-memory cache -> aynı gs:// için tekrar getDownloadURL çağrısını engeller
  final Map<String, String> _downloadUrlCache = {};

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
        .asyncMap((snapshot) async {
          final futures = snapshot.docs.map((doc) async {
            final data = doc.data();
            return await _mapFirestoreToEntityAsync(doc.id, data);
          }).toList();
          return await Future.wait(futures);
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
        .asyncMap((snapshot) async {
          final futures = snapshot.docs.map((doc) async {
            final data = doc.data();
            return await _mapFirestoreToFollowEntityAsync(doc.id, data);
          }).toList();
          return await Future.wait(futures);
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

  // ---- HELPERS ----
  Future<String> _resolveStorageOrUrl(String? rawUrl) async {
    final url = (rawUrl ?? '').trim();

    if (url.isEmpty) {
      return FileService.defaultProfileImageUrl();
    }

    // Eğer zaten http veya https ise direkt döndür
    if (url.startsWith('http://') || url.startsWith('https://')) {
      return url;
    }

    // Eğer doğrudan Firebase Storage public download url ise (ör. firebase storage host link) return
    if (url.contains('firebasestorage.googleapis.com')) {
      return url;
    }

    // gs:// formatı için cache kontrolü ve getDownloadURL
    if (url.startsWith('gs://')) {
      // Cache'de varsa hızlı return
      if (_downloadUrlCache.containsKey(url)) {
        return _downloadUrlCache[url]!;
      }

      try {
        final ref = firebase_storage.FirebaseStorage.instance.refFromURL(url);
        final downloadUrl = await ref.getDownloadURL();
        // Cache'le
        _downloadUrlCache[url] = downloadUrl;
        return downloadUrl;
      } catch (e) {
        // Hata durumunda fallback
        // Loglama için print (isteğe göre LoggingService ile değiştirin)
        print('InboxRepositoryImpl: getDownloadURL failed for $url -> $e');
        return FileService.defaultProfileImageUrl();
      }
    }

    // Diğer formatlar (ör: storage path without gs://) için deneme:
    // Eğer "users/avatars/..." gibi path geliyorsa ref().child ile deneyebiliriz.
    if (!url.contains('/') || url.split('/').length < 2) {
      // muhtemelen geçersiz -> fallback
      return FileService.defaultProfileImageUrl();
    }

    try {
      // Deneme: treat as path under root
      final ref = firebase_storage.FirebaseStorage.instance.ref().child(url);
      final downloadUrl = await ref.getDownloadURL();
      // Cache key olarak path kullan
      _downloadUrlCache[url] = downloadUrl;
      return downloadUrl;
    } catch (e) {
      print(
        'InboxRepositoryImpl: fallback getDownloadURL failed for path $url -> $e',
      );
      return FileService.defaultProfileImageUrl();
    }
  }

  // MAPPERS (ASYNCHRONOUS)
  // Mapper 1: Genel Bildirimler
  Future<NotificationEntity> _mapFirestoreToEntityAsync(
    String id,
    Map<String, dynamic> data,
  ) async {
    final typeString = (data['type'] as String?) ?? '';
    final type = _notificationTypeFromString(typeString);

    final rawAvatar = (data['avatarUrl'] as String?) ?? '';
    final resolvedAvatar = await _resolveStorageOrUrl(rawAvatar);

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
  Future<FollowNotificationEntity> _mapFirestoreToFollowEntityAsync(
    String id,
    Map<String, dynamic> data,
  ) async {
    final statusString = (data['status'] as String?) ?? '';
    final status = _followStatusFromString(statusString);

    // Bazı koleksiyonlarda alan adı profileUrl veya profileImageUrl olabilir; ikisini de kontrol ediyoruz
    final rawProfile =
        (data['profileUrl'] as String?) ??
        (data['profileImageUrl'] as String?) ??
        (data['avatarUrl'] as String?);

    final resolvedProfile = await _resolveStorageOrUrl(rawProfile);

    return FollowNotificationEntity(
      userID: id,
      username: (data['username'] as String?) ?? 'Kullanıcı',
      profileImageUrl:
          (data['profileImageUrl'] as String?) ??
          FileService.defaultProfileImageUrl(),
      status: status,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  // String -> Enum yardımcıları
  NotificationType _notificationTypeFromString(String s) {
    switch (s) {
      case 'invite':
        return NotificationType.invite;
      case 'cancel':
        return NotificationType.cancel;
      case 'updateTime':
        return NotificationType.updateTime;
      case 'updateLocation':
        return NotificationType.updateLocation;
      case 'warning':
        return NotificationType.warning;
      case 'tag':
        return NotificationType.tag;
      case 'badgeWin':
        return NotificationType.badgeWin;
      case 'badgeProgress':
        return NotificationType.badgeProgress;
      case 'participants':
        return NotificationType.participants;
      case 'left':
        return NotificationType.left;
      case 'timeEnding':
        return NotificationType.timeEnding;
      case 'created':
        return NotificationType.created;
      case 'startingSoon':
        return NotificationType.startingSoon;
      case 'earlyStart':
        return NotificationType.earlyStart;
      case 'join':
      default:
        return NotificationType.join;
    }
  }

  FollowStatus _followStatusFromString(String s) {
    switch (s) {
      case 'following':
        return FollowStatus.following;
      case 'sent':
        return FollowStatus.sent;
      case 'pending':
        return FollowStatus.pending;
      case 'none':
      default:
        return FollowStatus.none;
    }
  }
}
