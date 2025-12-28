// lib/core/services/session/session_service_impl.dart

import 'dart:async';

import 'package:bulusalim/core/utils/logging/logging_service.dart';
import 'package:bulusalim/domain/entities/feed/event/event_entity.dart';
import 'package:bulusalim/domain/entities/user/user_entity.dart';
import 'package:bulusalim/domain/repositories/user_repository.dart';
import 'package:bulusalim/domain/services/auth_service.dart';
import 'package:bulusalim/domain/services/session_service.dart';
import 'package:flutter/foundation.dart';

class SessionServiceImpl implements SessionService {
  SessionServiceImpl({
    required AuthService authService,
    required UserRepository userRepository,
    required LoggingService logger,
  }) : _authService = authService,
       _userRepository = userRepository,
       _logger = logger;

  final AuthService _authService;
  final UserRepository _userRepository;
  final LoggingService _logger;

  // --- STATE HOLDERS (Notifiers) ---
  final ValueNotifier<UserEntity?> _userNotifier = ValueNotifier(null);
  // Interface List<EventEntity> istiyor, bu yüzden tipi düzelttik:
  final ValueNotifier<List<EventEntity>?> _eventsNotifier = ValueNotifier(null);

  // --- STREAM SUBSCRIPTIONS ---
  StreamSubscription<String?>? _authSubscription;
  StreamSubscription<List<EventEntity>>? _eventsSubscription;

  // --- GETTERS (Interface Implementation) ---
  @override
  ValueListenable<UserEntity?> get userListenable => _userNotifier;

  @override
  ValueListenable<List<EventEntity>?> get ongoingEventsListenable =>
      _eventsNotifier;

  @override
  UserEntity? get currentUser => _userNotifier.value;

  @override
  List<EventEntity>? get ongoingEvents => _eventsNotifier.value;

  // --- INIT ---
  @override
  Future<void> init() async {
    // Auth durumunu dinlemeye başla (Login/Logout)
    _authSubscription = _authService.onAuthStateChanged.listen(
      _onAuthStateChanged,
    );
  }

  // --- LOGIC ---
  Future<void> _onAuthStateChanged(String? userId) async {
    // 1. Önceki event dinleyicisini temizle (Kullanıcı değiştiyse eskisini dinlemeyi bırakmalıyız)
    await _eventsSubscription?.cancel();
    _eventsSubscription = null;

    if (userId == null) {
      // CASE: LOGOUT
      _logger.info('SessionService: Kullanıcı çıkış yaptı.');
      _userNotifier.value = null;
      _eventsNotifier.value = null;
    } else {
      // CASE: LOGIN
      _logger.info(
        'SessionService: Kullanıcı giriş yaptı. Veriler getiriliyor...',
      );

      try {
        // 2. Kullanıcı verisini bir kere fetch et (Veya burayı da stream yapabilirsin)
        final userEntity = await _userRepository.getUser(userId);

        if (userEntity != null) {
          _userNotifier.value = userEntity;

          // 3. Kullanıcının aktif eventlerini dinlemeye başla (Realtime Updates)
          _eventsSubscription = _userRepository
              .watchOngoingEvents(userId)
              .listen(
                (events) {
                  // Event listesi her güncellendiğinde UI'ı haberdar et
                  _eventsNotifier.value = events;
                },
                onError: (error) {
                  _logger.error('SessionService: Event Stream Hatası - $error');
                  // Hata durumunda event listesini boşaltmak isteyebilirsin:
                  _eventsNotifier.value = [];
                },
              );
        } else {
          _logger.warn(
            'SessionService: Auth ID var ama User DB kaydı bulunamadı.',
          );
        }
      } catch (e) {
        _logger.error('SessionService: Kullanıcı verisi çekilirken hata - $e');
      }
    }
    _logger.info(
      'SessionService: Kullanıcı verisi yüklendi. Aktif event sayısı: ${_eventsNotifier.value?.length ?? 0}',
    );
  }

  // --- SETTERS (State Manipulation) ---
  @override
  void updateUser(UserEntity? user) {
    // Sadece veri değiştiyse güncelle
    if (_userNotifier.value != user) {
      _logger.info('SessionService: Kullanıcı verisi manuel güncellendi.');
      _userNotifier.value = user;
    }
  }

  // --- DISPOSE ---
  @override
  void dispose() {
    _authSubscription?.cancel();
    _eventsSubscription?.cancel();
    _userNotifier.dispose();
    _eventsNotifier.dispose();
  }
}
