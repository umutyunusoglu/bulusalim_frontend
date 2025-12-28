import 'package:bulusalim/domain/entities/feed/event/event_entity.dart';
import 'package:bulusalim/domain/entities/user/user_entity.dart';
import 'package:flutter/foundation.dart';

abstract class SessionService {
  // --- OKUMA (READ - UI bunları dinler) ---
  /// Kullanıcı durumu değiştiğinde (Giriş/Çıkış/Güncelleme) tetiklenir
  ValueListenable<UserEntity?> get userListenable;

  /// Etkinlikler durumu değiştiğinde (Güncelleme) tetiklenir
  ValueListenable<List<EventEntity>?> get ongoingEventsListenable;

  /// Anlık değerlere senkron erişim (Snapshots)
  UserEntity? get currentUser;
  List<EventEntity>? get ongoingEvents;

  // --- YAZMA (WRITE - State güncellemeleri) ---
  /// Kullanıcı verisi manuel güncellenirse (Örn: Profil düzenleme sonrası)
  void updateUser(UserEntity? user);

  // --- YAŞAM DÖNGÜSÜ ---
  /// Servisi başlatır ve Auth dinleyicisini kurar
  Future<void> init();

  /// Servisi kapatır
  void dispose();
}
