// This is the service responsible for generating share links for posts and events and parsing incoming share links to navigate to the appropriate content within the app.
import 'dart:typed_data';

abstract class ShareLinksService {
  Future<void> sharePost(String postId);

  Future<void> sharePostToInstagramStory(String postId,
    {Uint8List? stickerImageBytes});

  Future<void> shareEvent(String eventId);

  Future<void> shareEventToInstagramStory(String eventId,
    {Uint8List? stickerImageBytes});

  Future<void> shareUserProfile(String userId);

  Future<void> shareUserProfileToInstagramStory(String userId,
    {Uint8List? stickerImageBytes});

  void setPendingDeepLink(String? deepLink);

  String? getPendingDeepLink();

  void clearPendingDeepLink();

  bool hasPendingDeepLink();
}
