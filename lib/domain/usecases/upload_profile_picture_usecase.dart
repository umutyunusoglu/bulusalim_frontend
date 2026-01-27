import 'dart:io';

import 'package:bulusalim/core/utils/logging/logging_service.dart';
import 'package:bulusalim/domain/services/file_service.dart';

class UploadProfilePicture {
  const UploadProfilePicture({
    required FileService fileService,
    required LoggingService loggingService,
  }) : _fileService = fileService,
       _loggingService = loggingService;

  final FileService _fileService;
  final LoggingService _loggingService;

  Future<String?> call(String userID, String filePath) async {
    try {
      final file = File(filePath);

      // 1. Dosya varlık kontrolü
      if (!file.existsSync()) {
        throw Exception('Dosya bulunamadı: $filePath');
      }

      final path =
          '${FileService.privateUsers}$userID/profile/images/profile.jpg';

      final downloadUrl = await _fileService.uploadFile(file, path);

      return downloadUrl;
    } catch (e) {
      _loggingService.error('Profil resmi yüklenirken hata oluştu: $e');
      rethrow;
    }
  }
}
