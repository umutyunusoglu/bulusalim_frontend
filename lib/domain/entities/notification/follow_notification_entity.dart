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
    required this.profileUrl,
    required this.message,
    required this.status,
    required this.createdAt,
  });

  final String userID;
  final String username;
  final String profileUrl;
  final String message;
  final FollowStatus status;
  final DateTime createdAt;
}
