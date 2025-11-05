import 'dart:io';

abstract class FileService {
  Future<String> uploadFile(
    String absoluteSourcePath,
    String absoluteTargetPath,
  );
  Future<String> getDownloadUrl(String filePath);

  Future<void> deleteFile(String filePath);
}
