// lib/core/services/session/session_service_impl.dart

import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:outnest/core/utils/logging/logging_service.dart';
import 'package:outnest/core/utils/types/types.dart';
import 'package:outnest/domain/entities/feed/event/event_entity.dart';
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
  StreamSubscription<List<Identifier>>? _followersSubscription;
  StreamSubscription<List<Identifier>>? _followeesSubscription;

  // --- PUBLIC GETTERS ---
  @override
  ValueListenable<SessionState> get stateListenable => _stateNotifier;

  @override
  SessionState get currentState => _stateNotifier.value;

  // Interface uyumluluğu için eski getterlar (Gerekirse)
  UserEntity? get currentUser => _stateNotifier.value.user;

  // --- INIT ---
  @override
  Future<void> init() async {
    _authSubscription = _authService.onAuthStateChanged.listen(
      _onAuthStateChanged,
    );
  }

  // --- LOGIC ---
  Future<void> _onAuthStateChanged(String? userId) async {
    // 1. Önceki tüm dinleyicileri kapat
    await _cancelUserStreams();

    if (userId == null) {
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
      _stateNotifier.value = _stateNotifier.value.copyWith(user: user);
    });

    // Events Stream: Sadece 'ongoingEvents' alanını günceller
    _eventsSubscription = _userRepository.watchOngoingEvents(userId).listen((
      events,
    ) {
      _stateNotifier.value = _stateNotifier.value.copyWith(
        ongoingEvents: events,
      );
    });

    // Followers Stream: Sadece 'followerIds' alanını günceller
    _followersSubscription = _userRepository.watchFollowers(userId).listen((
      ids,
    ) {
      _stateNotifier.value = _stateNotifier.value.copyWith(followerIds: ids);
    });

    // Followees Stream: Sadece 'followeeIds' alanını günceller
    _followeesSubscription = _userRepository.watchFollowees(userId).listen((
      ids,
    ) {
      _stateNotifier.value = _stateNotifier.value.copyWith(followeeIds: ids);
    });
  }

  Future<void> _cancelUserStreams() async {
    await _userSubscription?.cancel();
    await _eventsSubscription?.cancel();
    await _followersSubscription?.cancel();
    await _followeesSubscription?.cancel();

    _userSubscription = null;
    _eventsSubscription = null;
    _followersSubscription = null;
    _followeesSubscription = null;
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    _cancelUserStreams();
    _stateNotifier.dispose();
  }
}
