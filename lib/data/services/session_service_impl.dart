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
  final ValueNotifier<List<EventEntity>?> _eventsNotifier = ValueNotifier(null);

  // --- STREAM SUBSCRIPTIONS ---
  StreamSubscription<String?>? _authSubscription;
  StreamSubscription<List<EventEntity>>? _eventsSubscription;
  // [YENİ]: Kullanıcıyı canlı dinlemek için subscription
  StreamSubscription<UserEntity?>? _userSubscription;

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
    _userSubscription = null;
    _eventsSubscription = null;

    if (userId == null) {
      // CASE: LOGOUT
      _logger.info('SessionService: Kullanıcı çıkış yaptı.');
      _userNotifier.value = null;
      _eventsNotifier.value = null;
    } else {
      // CASE: LOGIN
      _logger.info(
        'SessionService: Kullanıcı giriş yaptı. Canlı takipler başlatılıyor...',
      );

      // 2. Kullanıcıyı canlı izlemeye başla (Stream)
      _userSubscription = _userRepository
          .watchUser(userId)
          .listen(
            (userEntity) {
              debugPrint('🔥 SESSION_SERVICE: Firebaseden yeni veri geldi!');
              // Stream her yeni veri attığında burası çalışır
              _userNotifier.value =
                  null; // Önce null yaparak "değişimi" garanti et
              _userNotifier.value = userEntity;
              debugPrint('🔥 NOTIFIER TETİKLENDİ: ValueNotifier güncellendi.');
              if (userEntity != null) {
                // Kullanıcı verisi başarıyla geldiyse ve Events henüz dinlenmiyorsa başlat.
                // Not: Events dinleyicisini if içine koymamızın sebebi, user null ise (db'de yoksa) event çekmemektir.
                // Ayrıca _eventsSubscription == null kontrolü yapıyoruz ki;
                // kullanıcı sadece adını güncellediğinde event stream'i tekrar tekrar başlatılmasın.
                if (_eventsSubscription == null) {
                  _startListeningEvents(userId);
                }
              } else {
                _logger.warn(
                  'SessionService: Auth ID var ama User DB kaydı (Stream) boş geldi.',
                );
              }
            },
            onError: (error) {
              _logger.error('SessionService: User Stream Hatası - $error');
            },
          );
    }
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
    _userSubscription?.cancel(); // [YENİ]: User dinleyicisini kapat
    _userNotifier.dispose();
    _eventsNotifier.dispose();
  }
}
