import 'package:outnest/application/get_it_service_locators/get_it_init.dart';
import 'package:outnest/domain/services/session_service.dart';

enum FollowStatus {
  following, // "takip ediliyor" (Gri Chip)
  sent, // "istek gönderildi" (Mavi yazılı Gri Chip)
  none, // "takip et" (Turuncu Buton)
  pending, // "kabul et / sil" (İki butonlu)
}

class FollowNotificationEntity {
  FollowNotificationEntity({
    required this.userID,
    required this.username,
    required this.profileImageUrl,
    required this.createdAt,
  }) {
    final SessionService sessionService = getIt<SessionService>();

    final isItFollowingMe =
        sessionService.currentState!.followers.contains(userID) ?? false;

    final isMyAccountPrivate = sessionService.currentUser?.isPrivate;

    if (isItFollowingMe || !isMyAccountPrivate!) {
      message = 'seni takip etmeye başladı.';
    } else {
      message = 'seni takip etmek istiyor.';
    }
  }

  final String userID;
  final String username;
  final String profileImageUrl;
  late final String message;
  final DateTime createdAt;
}
