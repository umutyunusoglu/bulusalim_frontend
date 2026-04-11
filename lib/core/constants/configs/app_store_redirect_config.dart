/// Configuration for app store redirect service
/// 
/// When a deep link is shared and the user doesn't have the app installed,
/// this service handles redirecting to the appropriate app store.
class AppStoreRedirectConfig {
  // Base URL for the redirect service (e.g., https://api.outnest.app/redirect)
  static const String redirectServiceBaseUrl =
      'https://api.outnest.app/redirect';

  // App store URLs for fallback
  static const String iosAppStoreUrl =
      'https://apps.apple.com/app/outnest/id1234567890';
  static const String androidPlayStoreUrl =
      'https://play.google.com/store/apps/details?id=app.outnest';

  // Endpoint paths
  static const String sharePostEndpoint = '/post';
  static const String shareEventEndpoint = '/event';
  static const String shareProfileEndpoint = '/profile';
  static const String linksEndpoint = '/links';

  /// Generate a redirect link for sharing
  /// 
  /// This URL should be used when sharing instead of direct deep links.
  /// The endpoint will:
  /// 1. If app is installed: open the deep link in the app
  /// 2. If app is not installed: redirect to app store
  /// 3. If user is on web: show a web-friendly preview
  static Uri getRedirectUrl(String type, String id) {
    final uri = Uri.parse(redirectServiceBaseUrl);
    return uri.replace(
      queryParameters: {
        'type': type, // 'post', 'event', 'profile'
        'id': id,
        'platform': 'auto', // auto-detect platform
      },
    );
  }

  /// Get fallback app store URL based on platform
  static String getFallbackStoreUrl(String platform) {
    if (platform.toLowerCase() == 'ios') {
      return iosAppStoreUrl;
    } else if (platform.toLowerCase() == 'android') {
      return androidPlayStoreUrl;
    }
    // Default to iOS if unknown
    return iosAppStoreUrl;
  }
}
