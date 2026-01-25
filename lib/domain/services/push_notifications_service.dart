/// Interface for managing push notifications service.
abstract class PushNotificationsService {
  /// Initializes the service and requests necessary permissions.
  Future<void> initialize();

  /// Returns the current FCM token for the device.
  Future<String?> getToken();

  /// Stream triggered when the token is refreshed.
  Stream<String> get onTokenRefresh;

  /// Subscribes to a specific topic.
  Future<void> subscribeToTopic(String topic);

  /// Unsubscribes from a specific topic.
  Future<void> unsubscribeFromTopic(String topic);

  /// Deletes the current token.
  Future<void> deleteToken();
}
