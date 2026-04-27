// This is the service responsible for generating share links for posts and events and parsing incoming share links to navigate to the appropriate content within the app.
abstract class ShareLinksService {
  Future<void> sharePost(String postId);

  Future<void> sharePostToInstagramStory(String postId);

  Future<void> shareEvent(String eventId);

  Future<void> shareEventToInstagramStory(String eventId);

  Future<void> shareUserProfile(String userId);

  Future<void> shareUserProfileToInstagramStory(String userId);

  void setPendingDeepLink(String? deepLink);

  String? getPendingDeepLink();

  void clearPendingDeepLink();

  bool hasPendingDeepLink();
}
