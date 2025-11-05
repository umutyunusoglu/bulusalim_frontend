import 'dart:io';

abstract class FileService {
  static const String rootPublic = 'Public/';
  static const String rootPrivate = 'Private/';

  static const String publicAppAssets = '${rootPublic}App/Assets/';
  static const String publicImages = '${publicAppAssets}Images/';
  static const String publicVideos = '${publicAppAssets}Videos/';

  static const String privateEvents = '${rootPrivate}Events/';
  static const String privateUsers = '${rootPrivate}Users/';
  static String userProfileImagePath(String userId, String fileName) =>
      '$privateUsers$userId/Profile/Images/$fileName';

  Future<String> uploadFile(
    String absoluteSourcePath,
    String absoluteTargetPath,
  );
  Future<String> getDownloadUrl(String filePath);

  Future<void> deleteFile(String filePath);
}
