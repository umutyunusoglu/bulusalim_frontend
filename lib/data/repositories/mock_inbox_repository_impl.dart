import 'dart:async';
import 'package:outnest/domain/entities/notification/follow_notification_entity.dart';
import 'package:outnest/domain/entities/notification/notification_entity.dart';
import 'package:outnest/domain/repositories/inbox_repository.dart';

class MockInboxRepository implements InboxRepository {
  @override
  Stream<List<NotificationEntity>> getNotificationsStream() {
    final now = DateTime.now();

    const userImage =
        'https://images.unsplash.com/photo-1506794778202-cad84cf45f1d?q=80&w=150&auto=format&fit=crop';

    const cinemaImage = userImage;
    final mockNotifications = <NotificationEntity>[
      // --- BUGÜN ---
      NotificationEntity(
        type: NotificationType.join,
        title: 'Bizimle beraber tracking yapmak ister misiniz???',
        message: 'buluşmasına katıldı.',
        profileImageUrl: userImage,
        createdAt: now.subtract(const Duration(minutes: 46)),
      ),
      NotificationEntity(
        type: NotificationType.invite,
        title: 'yarkin.yoruk',
        message: 'seni Sinema Gecesi buluşmasına çağırıyor.',
        actionText: 'Buluşma kartını görüntüle.',
        profileImageUrl: userImage,
        createdAt: now.subtract(const Duration(hours: 1)),
      ),
      NotificationEntity(
        type: NotificationType.cancel,
        title: 'Katıldığın Sinema Gecesi',
        message: 'buluşması iptal edildi.',
        actionText: 'film temalı başka buluşmalara göz at.',
        profileImageUrl: userImage,
        createdAt: now.subtract(const Duration(hours: 1, minutes: 10)),
      ),

      // --- SON 7 GÜN ---
      NotificationEntity(
        type: NotificationType.updateTime,
        title: 'Katıldığın Sinema Gecesi',
        message: 'buluşmasının zamanı 25 Aralık 20.00 olarak güncellendi.',
        profileImageUrl: cinemaImage,
        createdAt: now.subtract(const Duration(hours: 24)),
      ),
      NotificationEntity(
        type: NotificationType.updateLocation,
        title: 'Katıldığın Sinema Gecesi',
        message: 'buluşmasının konumu Kült Kavaklıdere olarak güncellendi.',
        profileImageUrl: cinemaImage,
        createdAt: now.subtract(const Duration(hours: 25)),
      ),
      NotificationEntity(
        type: NotificationType.updateLocation,
        title: 'Katıldığın Sinema Gecesi',
        message: 'buluşmasının konumu Kült Kavaklıdere olarak güncellendi.',
        profileImageUrl: cinemaImage,
        createdAt: now.subtract(
          const Duration(hours: 26),
        ), // Tekrar eden bildirim örneği
      ),
      NotificationEntity(
        type: NotificationType.warning,
        title: '',
        message: 'Gönderdiğin şikayet alındı ve süreç ile ilgileniyoruz.',
        profileImageUrl: '',
        createdAt: now.subtract(const Duration(hours: 27)),
      ),
      NotificationEntity(
        type: NotificationType.tag,
        title: 'yarkin.yoruk',
        message: 'seni katıldığın Sinema Gecesi gönderisine etiketledi.',
        profileImageUrl: userImage,
        createdAt: now.subtract(const Duration(days: 1)),
      ),
      NotificationEntity(
        type: NotificationType.badgeProgress,
        title: 'ABC rozetini kazanmak',
        message: 'sadece 2 🏃 koşu uzağında hemen buluşma oluştur ya da katıl.',
        profileImageUrl: '', // Rozet alanı
        createdAt: now.subtract(const Duration(days: 1, hours: 2)),
      ),
      NotificationEntity(
        type: NotificationType.badgeWin,
        title: 'ABC rozetini kazandın!',
        message: 'Başarını görüntüle.',
        profileImageUrl: '', // Rozet alanı
        createdAt: now.subtract(const Duration(days: 1, hours: 3)),
      ),
      NotificationEntity(
        type: NotificationType.participants,
        title: 'Katıldığın Sinema Gecesi',
        message:
            'buluşmasının yeni katılımcıları var. Kimlerin katıldığını gör.',
        profileImageUrl: userImage,
        createdAt: now.subtract(const Duration(days: 2)),
      ),
      NotificationEntity(
        type: NotificationType.left,
        title: 'Katıldığın Sinema Gecesi',
        message: 'buluşmasından ayrılanlar var. Kimlerin ayrıldığını gör.',
        profileImageUrl: userImage,
        createdAt: now.subtract(const Duration(days: 2, hours: 1)),
      ),
      NotificationEntity(
        type: NotificationType.timeEnding,
        title: 'Sinema Gecesi',
        message:
            'buluşmasının süresi dolmak üzere. Çektiğin fotoğrafları paylaşmak için son 15 dakika!',
        profileImageUrl: userImage,
        createdAt: now.subtract(const Duration(days: 2, hours: 4)),
      ),
      NotificationEntity(
        type: NotificationType.created,
        title: 'yarkin.yoruk',
        message: 'Çay buluşmasını oluşturdu. İlgini çekebilir.',
        profileImageUrl: userImage,
        createdAt: now.subtract(const Duration(days: 3)),
      ),
      NotificationEntity(
        type: NotificationType.startingSoon,
        title: 'Katıldığın Çay',
        message:
            'buluşmasının başlamasına 1 saat kaldı. Buluşmaya katılmayı unutma!',
        profileImageUrl: userImage,
        createdAt: now.subtract(const Duration(days: 3, hours: 1)),
      ),
      NotificationEntity(
        type: NotificationType.earlyStart,
        title: 'Katıldığın Çay',
        message: 'buluşması saatinden erken başlatıldı. Buluşmayı kaçırma!',
        profileImageUrl: userImage,
        createdAt: now.subtract(const Duration(days: 3, hours: 2)),
      ),
    ];

    return Stream.value(mockNotifications);
  }

  @override
  Stream<int> getUnreadCountStream() {
    return Stream.value(20);
  }

  @override
  Future<void> markAsRead(String notificationId) async {
    // Mock işlem
  }
  @override
  Stream<List<FollowNotificationEntity>> getFollowRequestsStream() {
    final now = DateTime.now();
    const userImage =
        'https://images.unsplash.com/photo-1506794778202-cad84cf45f1d?q=80&w=150&auto=format&fit=crop';

    final requests = <FollowNotificationEntity>[
      // --- BUGÜN ---
      FollowNotificationEntity(
        userID: '1',
        username: 'yarkin.yoruk',
        profileImageUrl: userImage,
        status: FollowStatus.following, // "takip ediliyor"
        createdAt: now.subtract(const Duration(minutes: 16)),
      ),
      FollowNotificationEntity(
        userID: '2',
        username: 'yarkin.yoruk',
        profileImageUrl: userImage,
        status: FollowStatus.sent, // "istek gönderildi"
        createdAt: now.subtract(const Duration(minutes: 16)),
      ),
      FollowNotificationEntity(
        userID: '3',
        username: 'yarkin.yoruk',
        profileImageUrl: userImage,
        status: FollowStatus.none, // "takip et"
        createdAt: now.subtract(const Duration(minutes: 16)),
      ),
      FollowNotificationEntity(
        userID: '4',
        username: 'yarkin.yoruk',
        profileImageUrl: userImage,
        status: FollowStatus.pending, // "kabul et / sil"
        createdAt: now.subtract(const Duration(minutes: 8)),
      ),

      // --- SON 7 GÜN ---
      FollowNotificationEntity(
        userID: '5',
        username: 'yarkin.yoruk',
        profileImageUrl: userImage,
        status: FollowStatus.following,
        createdAt: now.subtract(const Duration(days: 1)),
      ),
      FollowNotificationEntity(
        userID: '6',
        username: 'yarkin.yoruk',
        profileImageUrl: userImage,
        status: FollowStatus.sent,
        createdAt: now.subtract(const Duration(days: 2)),
      ),
      FollowNotificationEntity(
        userID: '7',
        username: 'yarkin.yoruk',
        profileImageUrl: userImage,
        status: FollowStatus.none,
        createdAt: now.subtract(const Duration(days: 3)),
      ),
      FollowNotificationEntity(
        userID: '8',
        username: 'yarkin.yoruk',
        profileImageUrl: userImage,
        status: FollowStatus.pending,
        createdAt: now.subtract(const Duration(days: 4)),
      ),
    ];

    return Stream.value(requests);
  }
}
