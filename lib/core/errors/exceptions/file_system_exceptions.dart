import 'dart:io';

class FileNotFoundException implements FileSystemException {
  FileNotFoundException(this.message, this.path);
  @override
  final String message;

  @override
  final String path;

  @override
  final OSError? osError = null;

  @override
  String toString() {
    return 'FileNotFoundException: $message';
  }
}
