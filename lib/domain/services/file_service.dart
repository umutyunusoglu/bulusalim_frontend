import 'dart:io';

abstract class FileService {
  Future<String> uploadFile(
    String absoluteSourcePath,
    String absoluteTargetPath,
  );
  Future<void> deleteFile(String filePath);
  Future<File> getFile(String filePath);
}
