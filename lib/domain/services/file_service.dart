abstract class FileService {
  static const String rootPublic = 'Public/';
  static const String rootPrivate = 'Private/';

  static const String publicAppAssets = '$rootPublic/assets/';
  static const String publicImages = '${publicAppAssets}images/';
  static const String publicVideos = '${publicAppAssets}videos/';

  static const String privateEvents = '${rootPrivate}Events/';
  static const String privateUsers = '${rootPrivate}Users/';

  static String userProfileImagePath(String userId, String fileName) =>
      '$privateUsers$userId/profile/images/$fileName';

  static String postImagePath(
    String userId,
    String postId,
    String fileName,
  ) => '$privateUsers$userId/posts/$postId/images/$fileName';

  Future<String> uploadFile(
    String absoluteSourcePath,
    String absoluteTargetPath,
  );
  Future<String> getDownloadUrl(String filePath);

  Future<void> deleteFile(String filePath);
}
