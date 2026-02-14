enum NotificationType {
  join, // Biri katıldı
  invite, // Davet (Butonlu)
  cancel, // İptal (Kırmızı/Gri)
  update, // Zaman/Konum değişikliği
  warning, // Şikayet/Uyarı
  tag, // Etiketleme
  badge, // Rozet kazanımı
  reminder, // Hatırlatıcı (1 saat kaldı vb.)
  general, // Standart
}

class NotificationModel {
  NotificationModel({
    required this.id,
    required this.type,
    required this.title,
    required this.message,
    required this.profileImageUrl,
    required this.createdAt,
    this.isRead = false,
    this.actionUrl,
    this.highlightText,
  });
  final String id;
  final NotificationType type;
  final String title; // Örn: "yarkin.yoruk" veya "Katıldığın..."
  final String message; // Örn: "seni Sinema Gecesi buluşmasına çağırıyor"
  final String profileImageUrl;
  final DateTime createdAt;
  final bool isRead;
  final String? actionUrl; // Tıklanınca gidilecek yer (varsa)
  final String? highlightText;
}
