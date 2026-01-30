// lib/core/services/session/session_service_impl.dart

import 'dart:async';

import 'package:outnest/core/utils/logging/logging_service.dart';
import 'package:outnest/core/utils/types/types.dart';
import 'package:outnest/domain/entities/feed/event/event_entity.dart';
import 'package:outnest/domain/entities/user/user_entity.dart';
import 'package:outnest/domain/repositories/user_repository.dart';
import 'package:outnest/domain/services/auth_service.dart';
import 'package:outnest/domain/services/session_service.dart';
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
  final ValueNotifier<List<EventEntity>?> _eventsNotifier = ValueNotifier(null);

  // --- STREAM SUBSCRIPTIONS ---
  StreamSubscription<String?>? _authSubscription;
  StreamSubscription<List<EventEntity>>? _eventsSubscription;
  // [YENİ]: Kullanıcıyı canlı dinlemek için subscription
  StreamSubscription<UserEntity?>? _userSubscription;
  StreamSubscription<List<Identifier>>? _followersSubscription;
  StreamSubscription<List<Identifier>>? _followeesSubscription;

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
    _authSubscription = _authService.onAuthStateChanged.listen(
      _onAuthStateChanged,
    );
  }

  // --- LOGIC ---
  Future<void> _onAuthStateChanged(String? userId) async {
    // 1. Önceki tüm dinleyicileri temizle
    await _userSubscription?.cancel();
    await _eventsSubscription?.cancel();
    await _followersSubscription?.cancel(); // [YENİ]
    await _followeesSubscription?.cancel(); // [YENİ]

    _userSubscription = null;
    _eventsSubscription = null;
    _followersSubscription = null; // [YENİ]
    _followeesSubscription = null; // [YENİ]

    if (userId == null) {
      _userNotifier.value = null;
      _eventsNotifier.value = null;
    } else {
      // 2. Kullanıcıyı canlı izlemeye başla
      _userSubscription = _userRepository.watchUser(userId).listen((
        userEntity,
      ) {
        // Notifier'ı yeni gelen temel verilerle güncelle
        _userNotifier.value = userEntity;

        if (userEntity != null) {
          // Eventleri dinle
          if (_eventsSubscription == null) _startListeningEvents(userId);

          // [YENİ]: Takipçileri ve Takip Edilenleri dinle
          if (_followersSubscription == null) _startListeningFollowers(userId);
          if (_followeesSubscription == null) _startListeningFollowees(userId);
        }
      });
    }
  }

  void _startListeningFollowers(String userId) {
    _followersSubscription = _userRepository.watchFollowers(userId).listen(
      (followerIds) {
        final currentUser = _userNotifier.value;
        if (currentUser != null) {
          _userNotifier.value = currentUser.copyWith(
            followerIds: followerIds,
            followerCount: followerIds.length, // Dinamik count güncellemesi
          );
        }
      },
      onError: (e) => _logger.error('Followers Stream Hatası: $e'),
    );
  }

  void _startListeningFollowees(String userId) {
    _followeesSubscription = _userRepository.watchFollowees(userId).listen(
      (followeeIds) {
        final currentUser = _userNotifier.value;
        if (currentUser != null) {
          _userNotifier.value = currentUser.copyWith(
            followeeIds: followeeIds,
            followeeCount: followeeIds.length, // Dinamik count güncellemesi
          );
        }
      },
      onError: (e) => _logger.error('Followees Stream Hatası: $e'),
    );
  }

  void _startListeningEvents(String userId) {
    _logger.info('SessionService: Event dinleyicisi başlatılıyor...');
    _eventsSubscription = _userRepository
        .watchOngoingEvents(userId)
        .listen(
          (events) {
            _eventsNotifier.value = events;
          },
          onError: (error) {
            _logger.error('SessionService: Event Stream Hatası - $error');
            _eventsNotifier.value = [];
          },
        );
  }

  // --- SETTERS (State Manipulation) ---
  @override
  void updateUser(UserEntity? user) {
    // Stream kullandığımız için manuel update'e çok ihtiyacımız kalmayabilir,
    // ancak optimistic update (anında arayüz güncelleme) için tutulabilir.
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
    _userSubscription?.cancel();
    _followersSubscription?.cancel(); // [EKLE]
    _followeesSubscription?.cancel(); // [EKLE]
    _userNotifier.dispose();
    _eventsNotifier.dispose();
  }
}
