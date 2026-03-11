// This is the service responsible for generating share links for posts and events and parsing incoming share links to navigate to the appropriate content within the app.
import 'package:outnest/data/models/links/deep_link_target.dart';

abstract class ShareLinksService {
  DeepLinkTarget parseLink(Uri uri);

  Future<void> sharePost(String postId);

  Future<void> shareEvent(String eventId);

  Future<void> shareUserProfile(String userId);
}
