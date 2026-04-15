import 'package:outnest/core/constants/configs/app_store_redirect_config.dart';
import 'package:outnest/core/utils/logging/logging_service.dart';
import 'package:outnest/application/get_it_service_locators/get_it_init.dart';
import 'package:outnest/domain/services/share_links_service.dart';
import 'package:share_plus/share_plus.dart';

class ShareLinksServiceImpl extends ShareLinksService {
  String? _pendingDeepLink;
  final LoggingService _logger = getIt<LoggingService>();

  static const String shareLinkPrefix =
      'https://outnest.app/share'; // This will be the base URL

  static Uri post(String postId) => Uri.parse(
    '$shareLinkPrefix/post/$postId',
  ); // For generating a share link for a post

  static Uri event(String eventId) => Uri.parse(
    '$shareLinkPrefix/event/$eventId',
  ); // For generating a share link for an event

  static Uri user(String userId) => Uri.parse(
    '$shareLinkPrefix/profile/$userId',
  ); // For generating a share link for a user profile

  /// Generate a redirect URL that handles app store fallback
  /// Should be used for external sharing (not in-app deep links)
  static Uri redirectPost(String postId) =>
      AppStoreRedirectConfig.getRedirectUrl('post', postId);

  static Uri redirectEvent(String eventId) =>
      AppStoreRedirectConfig.getRedirectUrl('event', eventId);

  static Uri redirectProfile(String userId) =>
      AppStoreRedirectConfig.getRedirectUrl('profile', userId);

  @override
  Future<void> sharePost(String postId) async {
    // Use direct share link for external sharing
    final link = post(postId);
    await SharePlus.instance.share(ShareParams(text: link.toString()));
  }

  @override
  Future<void> shareEvent(String eventId) async {
    // Use direct share link for external sharing
    final link = event(eventId);
    await SharePlus.instance.share(ShareParams(text: link.toString()));
  }

  @override
  Future<void> shareUserProfile(String userId) async {
    // Use direct share link for external sharing
    final link = user(userId);
    await SharePlus.instance.share(ShareParams(text: link.toString()));
  }

  @override
  void setPendingDeepLink(String? deepLink) {
    _logger.info('ShareLinksService: Setting pending deep link: $deepLink');
    _pendingDeepLink = deepLink;
  }

  @override
  String? getPendingDeepLink() {
    final link = _pendingDeepLink;
    if (link != null) {
      _logger.info('ShareLinksService: Retrieving pending deep link: $link');
      _pendingDeepLink = null;
    }
    return link;
  }

  @override
  void clearPendingDeepLink() {
    _logger.info('ShareLinksService: Clearing pending deep link');
    _pendingDeepLink = null;
  }

  @override
  bool hasPendingDeepLink() =>
      _pendingDeepLink != null && _pendingDeepLink!.isNotEmpty;
}
