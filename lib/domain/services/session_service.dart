import 'package:bulusalim/domain/entities/feed/event/event_entity.dart';
import 'package:bulusalim/domain/entities/user/user_entity.dart';
import 'package:flutter/foundation.dart';

abstract class SessionService {
  // --- OKUMA (READ - UI bunları dinler) ---
  /// Kullanıcı durumu değiştiğinde (Giriş/Çıkış/Güncelleme) tetiklenir
  ValueListenable<UserEntity?> get userListenable;

  /// Seçili event değiştiğinde tetiklenir
  ValueListenable<EventEntity?> get eventListenable;

  /// Anlık değerlere senkron erişim (Snapshots)
  UserEntity? get currentUser;
  EventEntity? get currentEvent;

  // --- YAZMA (WRITE - State güncellemeleri) ---
  /// Kullanıcı verisi manuel güncellenirse (Örn: Profil düzenleme sonrası)
  void updateUser(UserEntity? user);

  /// Uygulama içinde bir event seçildiğinde veya temizlendiğinde
  void selectEvent(EventEntity? event);

  // --- YAŞAM DÖNGÜSÜ ---
  /// Servisi başlatır ve Auth dinleyicisini kurar
  Future<void> init();

  /// Servisi kapatır
  void dispose();
}
