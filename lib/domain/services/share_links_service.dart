// This is the service responsible for generating share links for posts and events and parsing incoming share links to navigate to the appropriate content within the app.
import 'dart:typed_data';

abstract class ShareLinksService {
  Future<void> sharePost(String postId, {Uint8List? imageBytes});

  Future<void> shareEvent(String eventId, {Uint8List? imageBytes});

  Future<void> shareUserProfile(String userId, {Uint8List? imageBytes});

  void setPendingDeepLink(String? deepLink);

  String? getPendingDeepLink();

  void clearPendingDeepLink();

  bool hasPendingDeepLink();
}
