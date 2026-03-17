import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:outnest/core/utils/logging/logging_service.dart';
import 'package:outnest/domain/repositories/user_repository.dart';
import 'package:outnest/domain/services/push_notifications_service.dart';
import 'package:outnest/domain/services/session_service.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // NOT: Bu fonksiyon izole bir alanda çalıştığı için logger veya sınıf değişkenlerine erişemez.
  // Eğer burada bir işlem yapacaksan Firebase'i tekrar init etmen gerekebilir.
  print('Handling a background message: ${message.messageId}');
}

class PushNotificationsServiceImpl implements PushNotificationsService {
  PushNotificationsServiceImpl({
    required FirebaseMessaging firebaseMessaging,
    required LoggingService logger,
    required UserRepository userRepository,
    required SessionService sessionService,
  }) : _firebaseMessaging = firebaseMessaging,
       _logger = logger,
       _userRepository = userRepository,
       _sessionService = sessionService;

  final FirebaseMessaging _firebaseMessaging;
  final LoggingService _logger;
  final UserRepository _userRepository;
  final SessionService _sessionService;

  @override
  Future<void> initialize() async {
    _logger.info('Initializing Push Notifications Service');

    // 2. SessionState'i Dinle (Login/Logout takibi için)
    _sessionService.stateListenable.removeListener(
      _onSessionStateChanged,
    ); // idempotent - safe to call on re-login
    _sessionService.stateListenable.addListener(_onSessionStateChanged);

    // 3. Token Yenilenmesini Dinle (Firebase tarafında token değişirse)
    _firebaseMessaging.onTokenRefresh.listen((newToken) async {
      final user = _sessionService.currentUser;
      if (user != null) {
        _logger.info('FCM Token refreshed by Firebase, updating backend...');
        await _userRepository.updateFcmToken(user.userID, newToken);
      }
    });

    // 4. İlk açılışta kullanıcı zaten login ise token'ı hemen gönder
    if (_sessionService.currentUser != null) {
      await _updateTokenForUser(_sessionService.currentUser!.userID);
    }

    // Foreground mesajlarını dinle
    FirebaseMessaging.onMessage.listen(
      (message) => _logger.info('Foreground msg: ${message.messageId}'),
    );
  }

  // Session değiştiğinde çalışan callback
  void _onSessionStateChanged() {
    final user = _sessionService.currentUser;
    if (user != null) {
      _logger.info('Session updated: User detected, updating FCM token.');
      _updateTokenForUser(user.userID);
    } else {
      _logger.info('Session updated: No user (logged out).');
    }
  }

  Future<void> _updateTokenForUser(String userId) async {
    try {
      final token = await _firebaseMessaging.getToken();
      if (token != null) {
        await _userRepository.updateFcmToken(userId, token);
        _logger.info('FCM Token sync successful.');
      }
    } catch (e) {
      _logger.error('FCM Token sync failed: $e');
    }
  }

  @override
  Future<String?> getToken() {
    return _firebaseMessaging.getToken();
  }

  @override
  Future<void> deleteToken() {
    return _firebaseMessaging.deleteToken();
  }

  @override
  Stream<String> get onTokenRefresh => _firebaseMessaging.onTokenRefresh;

  @override
  Future<void> subscribeToTopic(String topic) {
    return _firebaseMessaging.subscribeToTopic(topic);
  }

  @override
  Future<void> unsubscribeFromTopic(String topic) {
    return _firebaseMessaging.unsubscribeFromTopic(topic);
  }
}
