import 'dart:io';

abstract class FileService {
  static const String rootPublic = 'public/';
  static const String rootPrivate = 'private/';

  static const String publicDefaults = '${rootPublic}defaults/';
  static const String publicAppAssets = '$rootPublic/assets/';
  static const String publicImages = '${publicAppAssets}images/';
  static const String publicVideos = '${publicAppAssets}videos/';

  static const String privateEvents = '${rootPrivate}events/';
  static const String privateUsers = '${rootPrivate}users/';

  static String userProfileImagePath(String userId, String fileName) =>
      '$privateUsers$userId/profile/images/$fileName';

  static String defaultProfileImageUrl() =>
      'assets/defaults/default_profile.jpg';

  static String communityEventPhotoPath(String uniqueId, String fileName) =>
      '$privateEvents/community_photos/$uniqueId/$fileName';
  static String postImagePath(
    String userId,
    String postId,
    String fileName,
  ) => '$privateUsers$userId/posts/$postId/images/$fileName';

  Future<String> uploadFileFromPath(
    String absoluteSourcePath,
    String absoluteTargetPath,
  );

  Future<String> uploadFile(
    File file,
    String absoluteTargetPath,
  );

  Future<String> getDownloadUrl(String filePath);

  Future<void> deleteFile(String filePath);
}
