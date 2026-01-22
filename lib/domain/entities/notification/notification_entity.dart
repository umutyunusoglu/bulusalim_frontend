enum NotificationType {
  join, // Katıldı
  invite, // Davet +
  cancel, // İptal +
  updateTime, // Zaman Güncellemesi +
  updateLocation, // Konum Güncellemesi +
  warning, // Şikayet/Uyarı +
  tag, // Etiketleme +
  badgeWin, // Rozet Kazanımı ?
  badgeProgress, // Rozet İlerlemesi ?
  participants, // Yeni Katılımcılar +
  left, // Ayrılanlar +
  timeEnding, // Süre Dolmak Üzere + -> düşün
  created, // Oluşturdu
  startingSoon, // Başlamasına Az Kaldı + -> düşün
  earlyStart, // Erken Başlatıldı +
}

class NotificationEntity {
  NotificationEntity({
    required this.type,
    required this.title,
    required this.message,
    required this.avatarUrl,
    required this.createdAt,
    this.actionText,
    this.isRead = false,
    this.eventId,
  });

  NotificationEntity copyWith({
    NotificationType? type,
    String? title,
    String? message,
    String? actionText,
    String? avatarUrl,
    DateTime? createdAt,
    bool? isRead,
    String? eventId,
  }) {
    return NotificationEntity(
      type: type ?? this.type,
      title: title ?? this.title,
      message: message ?? this.message,
      actionText: actionText ?? this.actionText,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      createdAt: createdAt ?? this.createdAt,
      isRead: isRead ?? this.isRead,
      eventId: eventId ?? this.eventId,
    );
  }

  final NotificationType type;
  final String title; // Kalın yazılacak kısım (Örn: Kullanıcı adı)
  final String message; // Normal metin
  final String?
  actionText; // Renkli aksiyon metni (Örn: "Buluşma kartını görüntüle")
  final String avatarUrl; // Profil resmi
  final DateTime createdAt;
  final bool isRead;
  final String? eventId;
}
