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
    required this.status,
    required this.createdAt,
  }) {
    switch (status) {
      case FollowStatus.following:
        message = 'seni takip etmeye başladı.';
      case FollowStatus.sent:
        message = 'seni takip etmeye başladı.';
      case FollowStatus.none:
        message = 'seni takip etmeye başladı.';
      case FollowStatus.pending:
        message = 'seni takip etmek istiyor.';
    }
  }

  final String userID;
  final String username;
  final String profileImageUrl;
  late final String message;
  final FollowStatus status;
  final DateTime createdAt;
}
