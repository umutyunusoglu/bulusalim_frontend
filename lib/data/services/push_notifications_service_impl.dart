import 'package:bulusalim/core/utils/logging/logging_service.dart';
import 'package:bulusalim/domain/services/push_notifications_service.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

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
  }) : _firebaseMessaging = firebaseMessaging,
       _logger = logger;

  final FirebaseMessaging _firebaseMessaging;
  final LoggingService _logger;

  @override
  Future<void> initialize() async {
    // TODO: implement initialize

    _logger.info('Initializing Push Notifications Service');

    final notificationSettings = await _firebaseMessaging.requestPermission();

    if (notificationSettings.authorizationStatus ==
        AuthorizationStatus.authorized) {
      _logger.info('Push notification permission granted.');
    } else if (notificationSettings.authorizationStatus ==
        AuthorizationStatus.provisional) {
      _logger.info('Push notification provisional permission granted.');
    } else {
      _logger.warn('Push notification permission denied.');
    }

    //TODO: Handle foreground, background, and terminated states
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      _logger.info('Received a foreground message: ${message.messageId}');
    });

    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      _logger.info('User opened a notification: ${message.messageId}');
    });

    _logger.info('Push Notifications Service initialized.');
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
