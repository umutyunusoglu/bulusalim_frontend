import 'dart:io';

import 'package:bulusalim/core/errors/exceptions/file_system_exceptions.dart';
import 'package:bulusalim/core/utils/logging/logging_service.dart';
import 'package:bulusalim/core/utils/types/types.dart';
import 'package:bulusalim/domain/services/file_service.dart';

class UploadUserPhotos {
  UploadUserPhotos({
    required FileService fileService,
    required LoggingService logger,
  }) : _fileService = fileService,
       _logger = logger;

  final FileService _fileService;
  final LoggingService _logger;

  /// First Upload + Update:
  /// - Slot based path: users/{uid}/photos/{i}.{ext}
  /// - Null or missing slots are skipped
  /// - If the same slot is uploaded again, it will be overwritten
  Future<List<String>> call(
    List<File?> photos,
    Identifier userID,
  ) async {
    final uploadFutures = <Future<String>>[];

    for (var i = 0; i < photos.length; i++) {
      final photo = photos[i];
      if (photo == null) continue; // skip if null

      final extension = _normalizeExtension(photo.path);
      final filePath = 'users/$userID/photos/$i.$extension';

      uploadFutures.add(_safeUpload(photo, filePath, i));
    }

    return Future.wait(uploadFutures);
  }

  Future<String> _safeUpload(File photo, String filePath, int index) async {
    try {
      return await _fileService.uploadFile(photo.absolute.path, filePath);
    } on FileNotFoundException catch (e) {
      _logger.error('Error uploading photo $index: $e');
      rethrow;
    } catch (e, st) {
      _logger.error('Unexpected error uploading photo $index: $e\n$st');
      rethrow;
    }
  }

  String _normalizeExtension(String path) {
    final ext = path.split('.').last.toLowerCase();
    return ext == 'jpeg' ? 'jpg' : ext;
  }
}
