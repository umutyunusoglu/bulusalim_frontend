import 'dart:async';
import 'package:bulusalim/domain/entities/notification/follow_notification_entity.dart';
import 'package:bulusalim/domain/entities/notification/notification_entity.dart';
import 'package:bulusalim/domain/repositories/inbox_repository.dart';

class MockInboxRepository implements InboxRepository {
  @override
  Stream<List<NotificationEntity>> getNotificationsStream() {
    final now = DateTime.now();

    const userImage =
        "https://images.unsplash.com/photo-1506794778202-cad84cf45f1d?q=80&w=150&auto=format&fit=crop";

    const cinemaImage = userImage;
    final mockNotifications = <NotificationEntity>[
      // --- BUGÜN ---
      NotificationEntity(
        id: '1',
        type: NotificationType.join,
        title: 'Bizimle beraber tracking yapmak ister misiniz???',
        message: 'buluşmasına katıldı.',
        avatarUrl: userImage,
        createdAt: now.subtract(const Duration(minutes: 46)),
      ),
      NotificationEntity(
        id: '2',
        type: NotificationType.invite,
        title: 'yarkin.yoruk',
        message: 'seni Sinema Gecesi buluşmasına çağırıyor.',
        actionText: 'Buluşma kartını görüntüle.',
        avatarUrl: userImage,
        createdAt: now.subtract(const Duration(hours: 1)),
      ),
      NotificationEntity(
        id: '3',
        type: NotificationType.cancel,
        title: 'Katıldığın Sinema Gecesi',
        message: 'buluşması iptal edildi.',
        actionText: 'film temalı başka etkinliklere göz at.',
        avatarUrl: userImage,
        createdAt: now.subtract(const Duration(hours: 1, minutes: 10)),
      ),

      // --- SON 7 GÜN ---
      NotificationEntity(
        id: '4',
        type: NotificationType.updateTime,
        title: 'Katıldığın Sinema Gecesi',
        message: 'buluşmasının zamanı 25 Aralık 20.00 olarak güncellendi.',
        avatarUrl: cinemaImage,
        createdAt: now.subtract(const Duration(hours: 24)),
      ),
      NotificationEntity(
        id: '5',
        type: NotificationType.updateLocation,
        title: 'Katıldığın Sinema Gecesi',
        message: 'buluşmasının konumu Kült Kavaklıdere olarak güncellendi.',
        avatarUrl: cinemaImage,
        createdAt: now.subtract(const Duration(hours: 25)),
      ),
      NotificationEntity(
        id: '6',
        type: NotificationType.updateLocation,
        title: 'Katıldığın Sinema Gecesi',
        message: 'buluşmasının konumu Kült Kavaklıdere olarak güncellendi.',
        avatarUrl: cinemaImage,
        createdAt: now.subtract(
          const Duration(hours: 26),
        ), // Tekrar eden bildirim örneği
      ),
      NotificationEntity(
        id: '7',
        type: NotificationType.warning,
        title: '',
        message: 'Gönderdiğin şikayet alındı ve süreç ile ilgileniyoruz.',
        avatarUrl: '',
        createdAt: now.subtract(const Duration(hours: 27)),
      ),
      NotificationEntity(
        id: '8',
        type: NotificationType.tag,
        title: 'yarkin.yoruk',
        message: 'seni katıldığın Sinema Gecesi gönderisine etiketledi.',
        avatarUrl: userImage,
        createdAt: now.subtract(const Duration(days: 1)),
      ),
      NotificationEntity(
        id: '9',
        type: NotificationType.badgeProgress,
        title: 'ABC rozetini kazanmak',
        message: 'sadece 2 🏃 koşu uzağında hemen buluşma oluştur ya da katıl.',
        avatarUrl: '', // Rozet alanı
        createdAt: now.subtract(const Duration(days: 1, hours: 2)),
      ),
      NotificationEntity(
        id: '10',
        type: NotificationType.badgeWin,
        title: 'ABC rozetini kazandın!',
        message: 'Başarını görüntüle.',
        avatarUrl: '', // Rozet alanı
        createdAt: now.subtract(const Duration(days: 1, hours: 3)),
      ),
      NotificationEntity(
        id: '11',
        type: NotificationType.participants,
        title: 'Katıldığın Sinema Gecesi',
        message:
            'buluşmasının yeni katılımcıları var. Kimlerin katıldığını gör.',
        avatarUrl: userImage,
        createdAt: now.subtract(const Duration(days: 2)),
      ),
      NotificationEntity(
        id: '12',
        type: NotificationType.left,
        title: 'Katıldığın Sinema Gecesi',
        message: 'buluşmasından ayrılanlar var. Kimlerin ayrıldığını gör.',
        avatarUrl: userImage,
        createdAt: now.subtract(const Duration(days: 2, hours: 1)),
      ),
      NotificationEntity(
        id: '13',
        type: NotificationType.timeEnding,
        title: 'Sinema Gecesi',
        message:
            'buluşmasının süresi dolmak üzere. Çektiğin fotoğrafları paylaşmak için son 15 dakika!',
        avatarUrl: userImage,
        createdAt: now.subtract(const Duration(days: 2, hours: 4)),
      ),
      NotificationEntity(
        id: '14',
        type: NotificationType.created,
        title: 'yarkin.yoruk',
        message: 'Çay buluşmasını oluşturdu. İlgini çekebilir.',
        avatarUrl: userImage,
        createdAt: now.subtract(const Duration(days: 3)),
      ),
      NotificationEntity(
        id: '15',
        type: NotificationType.startingSoon,
        title: 'Katıldığın Çay',
        message:
            'buluşmasının başlamasına 1 saat kaldı. Buluşmaya katılmayı unutma!',
        avatarUrl: userImage,
        createdAt: now.subtract(const Duration(days: 3, hours: 1)),
      ),
      NotificationEntity(
        id: '16',
        type: NotificationType.earlyStart,
        title: 'Katıldığın Çay',
        message: 'buluşması saatinden erken başlatıldı. Buluşmayı kaçırma!',
        avatarUrl: userImage,
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
    const String userImage =
        "https://images.unsplash.com/photo-1506794778202-cad84cf45f1d?q=80&w=150&auto=format&fit=crop";

    final requests = <FollowNotificationEntity>[
      // --- BUGÜN ---
      FollowNotificationEntity(
        id: '1',
        username: 'yarkin.yoruk',
        profileUrl: userImage,
        message: 'seni takip etmeye başladı.',
        status: FollowStatus.following, // "takip ediliyor"
        createdAt: now.subtract(const Duration(minutes: 16)),
      ),
      FollowNotificationEntity(
        id: '2',
        username: 'yarkin.yoruk',
        profileUrl: userImage,
        message: 'seni takip etmeye başladı.',
        status: FollowStatus.sent, // "istek gönderildi"
        createdAt: now.subtract(const Duration(minutes: 16)),
      ),
      FollowNotificationEntity(
        id: '3',
        username: 'yarkin.yoruk',
        profileUrl: userImage,
        message: 'seni takip etmeye başladı.',
        status: FollowStatus.none, // "takip et"
        createdAt: now.subtract(const Duration(minutes: 16)),
      ),
      FollowNotificationEntity(
        id: '4',
        username: 'yarkin.yoruk',
        profileUrl: userImage,
        message: 'seni takip etmek istiyor.',
        status: FollowStatus.pending, // "kabul et / sil"
        createdAt: now.subtract(const Duration(minutes: 8)),
      ),

      // --- SON 7 GÜN ---
      FollowNotificationEntity(
        id: '5',
        username: 'yarkin.yoruk',
        profileUrl: userImage,
        message: 'seni takip etmeye başladı.',
        status: FollowStatus.following,
        createdAt: now.subtract(const Duration(days: 1)),
      ),
      FollowNotificationEntity(
        id: '6',
        username: 'yarkin.yoruk',
        profileUrl: userImage,
        message: 'seni takip etmeye başladı.',
        status: FollowStatus.sent,
        createdAt: now.subtract(const Duration(days: 2)),
      ),
      FollowNotificationEntity(
        id: '7',
        username: 'yarkin.yoruk',
        profileUrl: userImage,
        message: 'seni takip etmeye başladı.',
        status: FollowStatus.none,
        createdAt: now.subtract(const Duration(days: 3)),
      ),
      FollowNotificationEntity(
        id: '8',
        username: 'yarkin.yoruk',
        profileUrl: userImage,
        message: 'seni takip etmek istiyor.',
        status: FollowStatus.pending,
        createdAt: now.subtract(const Duration(days: 4)),
      ),
    ];

    return Stream.value(requests);
  }
}
