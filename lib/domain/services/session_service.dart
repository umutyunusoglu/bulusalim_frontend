// lib/domain/services/session_service.dart

import 'package:flutter/foundation.dart';
import 'package:outnest/domain/entities/user/session_state.dart';
import 'package:outnest/domain/entities/user/user_entity.dart';

abstract class SessionService {
  // --- STATE ACCESS (READ) ---

  /// Tüm session verisini (User, Events, Followers, Followees) barındıran
  /// ve UI'ın dinlemesi gereken tek kaynak.
  ValueListenable<SessionState> get stateListenable;

  /// Anlık state değerine senkron erişim (Snapshot).
  SessionState get currentState;

  // --- CONVENIENCE GETTERS (Kolay Erişim) ---

  /// currentState.user için kısayol
  UserEntity? get currentUser;

  // --- YAŞAM DÖNGÜSÜ ---

  /// Servisi başlatır ve Auth/User dinleyicilerini kurar.
  Future<void> init();

  /// Servisi ve streamleri kapatır.
  void dispose();
}
