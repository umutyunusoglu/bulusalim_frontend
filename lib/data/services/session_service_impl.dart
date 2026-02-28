// lib/core/services/session/session_service_impl.dart

import 'dart:async';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/foundation.dart';
import 'package:outnest/core/utils/logging/logging_service.dart';
import 'package:outnest/core/utils/types/enums/event_status_enum.dart';
import 'package:outnest/core/utils/types/types.dart';
import 'package:outnest/domain/entities/feed/event/event_entity.dart';
import 'package:outnest/domain/entities/user/compact_user_entity.dart';
import 'package:outnest/domain/entities/user/session_state.dart';
import 'package:outnest/domain/entities/user/user_entity.dart';
import 'package:outnest/domain/repositories/user_repository.dart';
import 'package:outnest/domain/services/auth_service.dart';
import 'package:outnest/domain/services/session_service.dart';

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

  // --- SINGLE SOURCE OF TRUTH ---
  final ValueNotifier<SessionState> _stateNotifier = ValueNotifier(
    SessionState.empty,
  );

  // --- STREAM SUBSCRIPTIONS ---
  StreamSubscription<String?>? _authSubscription;
  StreamSubscription<UserEntity?>? _userSubscription;
  StreamSubscription<List<EventEntity>>? _eventsSubscription;
  StreamSubscription<List<CompactUserEntity>>? _followersSubscription;
  StreamSubscription<List<CompactUserEntity>>? _followeesSubscription;
  StreamSubscription<List<CompactUserEntity>>? _blockedUsersSubscription;

  // --- PUBLIC GETTERS ---
  @override
  ValueListenable<SessionState> get stateListenable => _stateNotifier;

  @override
  SessionState get currentState => _stateNotifier.value;

  // Interface uyumluluğu için eski getterlar (Gerekirse)
  @override
  UserEntity? get currentUser => _stateNotifier.value.user;

  @override
  List<EventEntity> get activeEvents =>
      _stateNotifier.value.ongoingEvents + _stateNotifier.value.upcomingEvents;

  // --- INIT ---
  @override
  Future<void> init() async {
    _authSubscription = _authService.onAuthStateChanged.listen(
      _onAuthStateChanged,
    );
  }

  Future<void> refreshSession() async {
    final userId = _authService.getCurrentUserID();
    if (userId != null) {
      await _onAuthStateChanged(userId);
    }
  }

  // --- LOGIC ---
  Future<void> _onAuthStateChanged(String? userId) async {
    // 1. Önceki tüm dinleyicileri kapat
    await _cancelUserStreams();

    if (userId == null) {
      await FirebaseAnalytics.instance.setUserId(id: userId);
      // 2. Logout: State'i tamamen sıfırla
      _stateNotifier.value = SessionState.empty;
      _logger.info('Session ended.');
    } else {
      // 3. Login: Streamleri başlat
      _logger.info('Session started for $userId');
      _startUserStreams(userId);
    }
  }

  void _startUserStreams(String userId) {
    // User Stream: Sadece 'user' alanını günceller
    _userSubscription = _userRepository.watchUser(userId).listen((user) {
      // 1. DURUM: Firestore'da doküman yok (null döndü)
      if (user == null) {
        // Eğer daha önce state'imizde bu kullanıcı VARDIYSA (yani null'a düştüyse)
        // Bu, hesabın veritabanından SİLİNDİĞİ anlamına gelir.
        if (_stateNotifier.value.user != null) {
          _logger.warn(
            'Hesap veritabanından silindi. Auth oturumu da kapatılıyor...',
          );
          _authService
              .signOut(); // Firestore'u dinlerken Auth'u buradan kapatıyoruz
          return;
        }

        // Eğer state zaten boşsa ve null geldiyse, bu YENİ bir kullanıcıdır.
        // Onu dışarı atmıyoruz, sadece user nesnesini null tutuyoruz (onboarding için).
        _stateNotifier.value = _stateNotifier.value.copyWith();
      } else {
        // 2. DURUM: Firestore'da doküman var (Kayıtlı kullanıcı)
        _stateNotifier.value = _stateNotifier.value.copyWith(user: user);
      }
    });

    _eventsSubscription = _userRepository.watchActiveEvents(userId).listen((
      events,
    ) {
      _stateNotifier.value = _stateNotifier.value.copyWith(
        ongoingEvents: events
            .where((e) => e.status == EventStatusEnum.ongoing)
            .toList(),
        upcomingEvents: events
            .where((e) => e.status == EventStatusEnum.upcoming)
            .toList(),
      );
    });

    // Followers Stream: Sadece 'followers' alanını günceller
    _followersSubscription = _userRepository.watchFollowers(userId).listen((
      followers,
    ) {
      _stateNotifier.value = _stateNotifier.value.copyWith(
        followers: followers,
      );
    });

    // Followees Stream: Sadece 'followees' alanını günceller
    _followeesSubscription = _userRepository.watchFollowees(userId).listen((
      followees,
    ) {
      _stateNotifier.value = _stateNotifier.value.copyWith(
        followees: followees,
      );
    });

    _blockedUsersSubscription = _userRepository
        .watchBlockedUsers(userId)
        .listen(
          (users) {
            _logger.info('Stream Update: ${users.length} blocked users found.');
            _stateNotifier.value = _stateNotifier.value.copyWith(
              blockedUsers: users,
            );
          },
          onError: (error) =>
              _logger.error('Error watching blocked users: $error'),
        );
  }

  Future<void> _cancelUserStreams() async {
    await _userSubscription?.cancel();
    await _eventsSubscription?.cancel();
    await _followersSubscription?.cancel();
    await _followeesSubscription?.cancel();
    await _blockedUsersSubscription?.cancel();

    _userSubscription = null;
    _eventsSubscription = null;
    _followersSubscription = null;
    _followeesSubscription = null;
    _blockedUsersSubscription = null;
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    _cancelUserStreams();
    _stateNotifier.dispose();
  }
}
