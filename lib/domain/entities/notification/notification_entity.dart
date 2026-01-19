enum NotificationType {
  join, // Katıldı
  invite, // Davet
  cancel, // İptal
  updateTime, // Zaman Güncellemesi
  updateLocation, // Konum Güncellemesi
  warning, // Şikayet/Uyarı
  tag, // Etiketleme
  badgeWin, // Rozet Kazanımı
  badgeProgress, // Rozet İlerlemesi
  participants, // Yeni Katılımcılar
  left, // Ayrılanlar
  timeEnding, // Süre Dolmak Üzere
  created, // Oluşturdu
  startingSoon, // Başlamasına Az Kaldı
  earlyStart, // Erken Başlatıldı
}

class NotificationEntity {
  final String id;
  final NotificationType type;
  final String title; // Kalın yazılacak kısım (Örn: Kullanıcı adı)
  final String message; // Normal metin
  final String?
  actionText; // Renkli aksiyon metni (Örn: "Buluşma kartını görüntüle")
  final String avatarUrl; // Profil resmi
  final DateTime createdAt;
  final bool isRead;
  final String? eventId;

  NotificationEntity({
    required this.id,
    required this.type,
    required this.title,
    required this.message,
    this.actionText,
    required this.avatarUrl,
    required this.createdAt,
    this.isRead = false,
    this.eventId,
  });
}
