// lib/core/services/session/session_service_impl.dart

import 'dart:async';

import 'package:bulusalim/core/utils/logging/logging_service.dart';
import 'package:bulusalim/domain/entities/feed/event/event_entity.dart';
// Domain Entities
import 'package:bulusalim/domain/entities/user/user_entity.dart';
// Domain Repositories
import 'package:bulusalim/domain/repositories/user_repository.dart';
import 'package:bulusalim/domain/services/auth_service.dart';
import 'package:bulusalim/domain/services/session_service.dart';
import 'package:flutter/foundation.dart';

// Interface

class SessionServiceImpl implements SessionService {
  SessionServiceImpl({
    required AuthService authService,
    required UserRepository userRepository,
    required LoggingService logger,
  }) : _authService = authService,
       _userRepository = userRepository,
       _logger = logger;
  final AuthService _authService; // ID ve Stream sağlar
  final UserRepository _userRepository; // Detaylı veriyi sağlar
  final LoggingService _logger;

  // State
  final ValueNotifier<UserEntity?> _userNotifier = ValueNotifier(null);
  final ValueNotifier<EventEntity?> _eventNotifier = ValueNotifier(null);

  StreamSubscription<String?>? _authSubscription;

  // --- GETTERS ---
  @override
  ValueListenable<UserEntity?> get userListenable => _userNotifier;
  @override
  ValueListenable<EventEntity?> get eventListenable => _eventNotifier;
  @override
  UserEntity? get currentUser => _userNotifier.value;
  @override
  EventEntity? get currentEvent => _eventNotifier.value;

  // --- INIT (KRİTİK BÖLÜM) ---
  @override
  Future<void> init() async {
    // 1. Önce manuel bir kontrol yapalım (Stream bazen ilk değeri hemen vermeyebilir)
    await _checkCurrentSession();

    // 2. Stream'i dinlemeye başla (Anlık değişimler için)
    _authSubscription = _authService.onAuthStateChanged.listen((userId) async {
      await _handleAuthChange(userId);
    });
  }

  // ID geldiğinde yapılacak işi tek bir fonksiyona topladım (DRY Prensibi)
  Future<void> _handleAuthChange(String? userId) async {
    if (userId == null) {
      // Çıkış yapılmış
      _logger.debug('Session: Kullanıcı oturumu kapalı.');
      _userNotifier.value = null;
      _eventNotifier.value = null;
    } else {
      // Giriş yapılmış -> ID var, şimdi UserRepository ile veriyi çekelim
      _logger.debug('Session: ID yakalandı ($userId), detaylar çekiliyor...');
      try {
        final userEntity = await _userRepository.getUser(userId);
        _userNotifier.value = userEntity;
      } on Exception catch (e) {
        _logger.error('Session: Kullanıcı verisi çekilemedi: $e');
        // Hata durumunda null yapabilir veya retry mekanizması kurabilirsin
        _userNotifier.value = null;
      }
    }
  }

  // Uygulama ilk açıldığında Stream gelmeden önceki boşluğu doldurmak için
  Future<void> _checkCurrentSession() async {
    final isLoggedIn = await _authService.isUserLoggedIn();
    if (isLoggedIn) {
      final userId = _authService.getCurrentUserID();

      await _handleAuthChange(userId);
    }
  }

  // --- SETTERS ---
  @override
  void updateUser(UserEntity? user) {
    if (_userNotifier.value != user) {
      _userNotifier.value = user;
    }
  }

  @override
  void selectEvent(EventEntity? event) {
    if (_eventNotifier.value != event) {
      _eventNotifier.value = event;
    }
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    _userNotifier.dispose();
    _eventNotifier.dispose();
  }
}
