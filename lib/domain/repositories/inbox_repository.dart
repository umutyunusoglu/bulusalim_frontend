import 'package:outnest/domain/entities/notification/follow_notification_entity.dart';
import 'package:outnest/domain/entities/notification/notification_entity.dart';

abstract class InboxRepository {
  // Bildirimleri canlı dinlemek için Stream
  Stream<List<NotificationEntity>> getNotificationsStream();

  // Genel bildirimleri okunduya çekmek için (üstteki kırmızı nokta temizliği)
  Future<void> markAllNotificationsRead();

  // Takip isteğini görüldü işaretlemek için
  Future<void> markFollowRequestsAsSeen(String followRequestId);

  // Okunmamış bildirim sayısı (Badge için)
  Future<bool> hasUnreadFollowRequest();

  Stream<List<FollowNotificationEntity>> getFollowRequestsStream();
}
