import 'package:outnest/domain/entities/notification/follow_notification_entity.dart';
import 'package:outnest/domain/entities/notification/notification_entity.dart';

abstract class InboxRepository {
  // Bildirimleri canlı dinlemek için Stream
  Stream<List<NotificationEntity>> getNotificationsStream();

  // Bildirimi okundu işaretlemek için
  Future<void> updateFollowNotificationRead(String notificationId);

  // Okunmamış bildirim sayısı (Badge için)
  Future<bool> hasUnreadFollowRequest();

  Stream<List<FollowNotificationEntity>> getFollowRequestsStream();
}
