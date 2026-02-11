import 'dart:io';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:outnest/core/errors/exceptions/file_system_exceptions.dart';
import 'package:outnest/core/errors/exceptions/security_exceptions.dart';
import 'package:outnest/core/utils/logging/logging_service.dart';
import 'package:outnest/domain/services/file_service.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

class FileServiceImpl implements FileService {
  FileServiceImpl({
    required FirebaseStorage storage,
    required LoggingService logger,
  }) : _storage = storage,
       _logger = logger;

  final FirebaseStorage _storage;
  final LoggingService _logger;

  Future<File> _compressImageIfNeeded(File file) async {
    final path = file.absolute.path;
    final extension = p.extension(path).toLowerCase();

    // Sadece görselleri sıkıştırıyoruz
    if (!(extension == '.jpg' || extension == '.jpeg' || extension == '.png')) {
      _logger.info('No compression needed for file: $path');
      return file;
    }

    try {
      final tempDir = await getTemporaryDirectory();
      final targetPath = p.join(
        tempDir.path,
        '${DateTime.now().millisecondsSinceEpoch}$extension',
      );

      _logger.info('Compressing image: $path');

      final result = await FlutterImageCompress.compressAndGetFile(
        path,
        targetPath,
        quality: 80,
        minWidth: 1080,
      );

      if (result == null) return file;

      // XFile'ı dart:io File nesnesine dönüştürüyoruz (Type inconsistency çözümü)
      return File(result.path);
    } catch (e) {
      _logger.error('Compression failed, using original file: $e');
      return file;
    }
  }

  @override
  Future<String> uploadFileFromPath(
    String absoluteSourcePath,
    String absoluteTargetPath,
  ) async {
    return uploadFile(File(absoluteSourcePath), absoluteTargetPath);
  }

  @override
  Future<String> uploadFile(File file, String absoluteTargetPath) async {
    if (!file.existsSync()) {
      throw FileNotFoundException('File not found', file.path);
    }

    try {
      // 1. Sıkıştırma işlemi (TODO çözüldü)
      final fileToUpload = await _compressImageIfNeeded(file);

      // 2. Upload işlemi
      final storageRef = _storage.ref().child(absoluteTargetPath);
      final uploadTask = storageRef.putFile(fileToUpload);

      await uploadTask;

      final downloadUrl = await storageRef.getDownloadURL();

      // Geçici dosyayı temizleme (opsiyonel ama iyi bir pratik)
      if (fileToUpload.path != file.path) {
        await fileToUpload.delete();
      }

      return downloadUrl;
    } on FirebaseException catch (e) {
      throw _handleFirebaseStorageException(e, absoluteTargetPath);
    } on Exception catch (e) {
      _logger.error('File Upload Exception: $e');
      throw FileSystemException('File Upload Exception: $e');
    }
  }

  @override
  Future<void> deleteFile(String filePath) async {
    try {
      final storageRef = _storage.ref().child(filePath);

      await storageRef.delete();
    } on FirebaseException catch (e) {
      throw _handleFirebaseStorageException(e, filePath);
    }
  }

  @override
  Future<String> getDownloadUrl(String filePath) async {
    try {
      final storageRef = _storage.ref().child(filePath);

      final downloadUrl = await storageRef.getDownloadURL();
      return downloadUrl;
    } on FirebaseException catch (e) {
      throw _handleFirebaseStorageException(e, filePath);
    } on Exception catch (e) {
      _logger.error('Get Download URL Exception: $e');
      throw FileSystemException('Get Download URL Exception: $e');
    }
  }

  Exception _handleFirebaseStorageException(
    FirebaseException e,
    String filePath,
  ) {
    _logger.error('Firebase Storage Exception: ${e.code}');
    switch (e.code) {
      case 'object-not-found':
        _logger.warn('File Not Found: $filePath');
        return FileNotFoundException('File Not Found: $filePath', filePath);
      case 'unauthorized':
        _logger.fatal('Permission Denied On Accessing Storage File: $filePath');
        return AuthorizationException(
          'Permission Denied On Accessing Storage File: $filePath',
        );
      case 'invalid-argument':
        _logger.error('Invalid Argument On Accessing Storage File: $filePath');
        return FileSystemException(
          'Invalid Argument On Accessing Storage File: $filePath',
        );

      case 'invalid-url':
        _logger.error('Invalid URL On Accessing Storage File: $filePath');
        return FileSystemException(
          'Invalid URL On Accessing Storage File: $filePath',
        );
      default:
        _logger.error('File System Exception Occurred: ${e.message}');

        return FileSystemException(
          'File System Exception Occurred: ${e.message}',
        );
    }
  }
}
