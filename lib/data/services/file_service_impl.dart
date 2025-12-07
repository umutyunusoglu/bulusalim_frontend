import 'dart:io';
import 'package:bulusalim/core/errors/exceptions/file_system_exceptions.dart';
import 'package:bulusalim/core/errors/exceptions/security_exceptions.dart';
import 'package:bulusalim/core/utils/logging/logging_service.dart';
import 'package:bulusalim/domain/services/file_service.dart';
import 'package:firebase_storage/firebase_storage.dart';

class FileServiceImpl implements FileService {
  FileServiceImpl({
    required FirebaseStorage storage,
    required LoggingService logger,
  }) : _storage = storage,
       _logger = logger;

  final FirebaseStorage _storage;
  final LoggingService _logger;

  @override
  Future<String> uploadFileFromPath(
    String absoluteSourcePath,
    String absoluteTargetPath,
  ) async {
    final file = File(absoluteSourcePath);
    if (!file.existsSync()) {
      throw FileNotFoundException('File not found', absoluteSourcePath);
    }

    try {
      final storageRef = _storage.ref().child(absoluteTargetPath);

      final uploadTask = storageRef.putFile(file);
      await uploadTask.whenComplete(() => null);
      return storageRef.getDownloadURL().then((downloadUrl) {
        return downloadUrl;
      });
    } on FirebaseException catch (e) {
      throw _handleFirebaseStorageException(e, absoluteTargetPath);
    } on Exception catch (e) {
      _logger.error('File Upload Exception: $e');
      throw FileSystemException('File Upload Exception: $e');
    }
  }

  @override
  Future<String> uploadFile(File file, String absoluteTargetPath) async {
    if (!file.existsSync()) {
      throw FileNotFoundException('File not found', file.path);
    }

    try {
      final storageRef = _storage.ref().child(absoluteTargetPath);

      final uploadTask = storageRef.putFile(file);
      await uploadTask.whenComplete(() => null);
      return storageRef.getDownloadURL().then((downloadUrl) {
        return downloadUrl;
      });
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
