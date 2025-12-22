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

  StreamSubscription<List<EventEntity>>? _eventsSubscription;
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
    // Auth dinleyicisi
    _authSubscription = _authService.onAuthStateChanged.listen((
      userID,
    ) async {
      // 1. Önce eski etkinlik dinleyicisini kapat (Memory Leak önlemi)
      await _eventsSubscription?.cancel();
      _eventsSubscription = null;

      if (userID == null) {
        _userNotifier.value = null;
        _eventNotifier.value = null;
      } else {
        // 2. Kullanıcı Giriş Yaptı: Önce temel bilgileri çek
        final userEntity = await _userRepository.getUser(userID);
        if (userEntity != null) {
          _userNotifier.value = userEntity;

          // 3. VE ŞİMDİ CANLI YAYINA BAĞLAN (Active Events Stream)
          _eventsSubscription = _userRepository
              .watchActiveEvents(userID)
              .listen(
                (realTimeEvents) {
                  _updateUserEvents(realTimeEvents);

                  _refreshCurrentEventState(realTimeEvents);
                },
                onError: (Object error) {
                  _logger.error('Event Stream Hatası: $error');
                },
              );
        }
      }
    });
  }

  void _updateUserEvents(List<EventEntity> newEvents) {
    final currentUser = _userNotifier.value;
    if (currentUser != null) {
      _userNotifier.value = currentUser.copyWith(
        activeEvents: newEvents,
      );
    }
  }

  void _refreshCurrentEventState(List<EventEntity> events) {
    try {
      final ongoingEvent = events.firstWhere(
        (e) => e.currentUserStatus == 'ongoing',
      );

      _eventNotifier.value = ongoingEvent;
    } on Exception {
      if (events.isNotEmpty) {
        _eventNotifier.value = events.first;
      } else {
        _eventNotifier.value = null;
      }
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
    _eventsSubscription?.cancel();
    _userNotifier.dispose();

    _eventNotifier.dispose();
  }
}
