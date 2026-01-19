enum FollowStatus {
  following, // "takip ediliyor" (Gri Chip)
  sent, // "istek gönderildi" (Mavi yazılı Gri Chip)
  none, // "takip et" (Turuncu Buton)
  pending, // "kabul et / sil" (İki butonlu)
}

class FollowNotificationEntity {
  final String id;
  final String username;
  final String profileUrl;
  final String message;
  final FollowStatus status;
  final DateTime createdAt;

  FollowNotificationEntity({
    required this.id,
    required this.username,
    required this.profileUrl,
    required this.message,
    required this.status,
    required this.createdAt,
  });
}
