import 'dart:io';

import 'package:flutter/services.dart';
import 'package:outnest/core/constants/configs/app_store_redirect_config.dart';
import 'package:outnest/core/utils/logging/logging_service.dart';
import 'package:outnest/application/get_it_service_locators/get_it_init.dart';
import 'package:outnest/domain/services/share_links_service.dart';
import 'package:share_plus/share_plus.dart';

class ShareLinksServiceImpl extends ShareLinksService {
  static const MethodChannel _instagramStoryChannel = MethodChannel(
    'outnest/share/instagram_story',
  );

  String? _pendingDeepLink;
  final LoggingService _logger = getIt<LoggingService>();

  static const String _appName = 'Outnest';

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

  static String _buildShareMessage({
    required String contentLabel,
    required Uri link,
  }) => '$contentLabel $_appName\n${link.toString()}';

  Future<void> _shareContent({
    required String contentLabel,
    required Uri link,
  }) async {
    final text = _buildShareMessage(contentLabel: contentLabel, link: link);
    await SharePlus.instance.share(ShareParams(text: text));
  }

  Future<bool> _shareToInstagramStory({
    required String contentLabel,
    required Uri link,
  }) async {
    if (!Platform.isIOS) return false;

    try {
      final shared = await _instagramStoryChannel.invokeMethod<bool>(
        'shareToInstagramStory',
        {
          'message': '$contentLabel $_appName',
          'link': link.toString(),
        },
      );
      return shared ?? false;
    } on PlatformException catch (e) {
      _logger.warn('Instagram story share failed: ${e.message}');
      return false;
    } catch (e) {
      _logger.warn('Unexpected Instagram story share failure: $e');
      return false;
    }
  }

  @override
  Future<void> sharePost(String postId) async {
    final link = post(postId);
    await _shareContent(contentLabel: 'Bu gönderiye göz at -', link: link);
  }

  @override
  Future<void> sharePostToInstagramStory(String postId) async {
    final link = post(postId);
    final shared = await _shareToInstagramStory(
      contentLabel: 'Bu gönderiye göz at -',
      link: link,
    );
    if (!shared) {
      await _shareContent(contentLabel: 'Bu gönderiye göz at -', link: link);
    }
  }

  @override
  Future<void> shareEvent(String eventId) async {
    final link = event(eventId);
    await _shareContent(contentLabel: 'Bu etkinliğe göz at -', link: link);
  }

  @override
  Future<void> shareEventToInstagramStory(String eventId) async {
    final link = event(eventId);
    final shared = await _shareToInstagramStory(
      contentLabel: 'Bu etkinliğe göz at -',
      link: link,
    );
    if (!shared) {
      await _shareContent(contentLabel: 'Bu etkinliğe göz at -', link: link);
    }
  }

  @override
  Future<void> shareUserProfile(String userId) async {
    final link = user(userId);
    await _shareContent(contentLabel: 'Bu profile göz at -', link: link);
  }

  @override
  Future<void> shareUserProfileToInstagramStory(String userId) async {
    final link = user(userId);
    final shared = await _shareToInstagramStory(
      contentLabel: 'Bu profile göz at -',
      link: link,
    );
    if (!shared) {
      await _shareContent(contentLabel: 'Bu profile göz at -', link: link);
    }
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
