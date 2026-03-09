import 'dart:io';

import 'package:outnest/core/utils/logging/logging_service.dart';
import 'package:outnest/domain/services/file_service.dart';
import 'package:outnest/domain/services/security_service.dart';

class UploadCommunityPicture {
  const UploadCommunityPicture({
    required FileService fileService,
    required LoggingService loggingService,
    required SecurityService securityService,
  }) : _fileService = fileService,
       _loggingService = loggingService,
       _securityService = securityService;

  final FileService _fileService;
  final LoggingService _loggingService;
  final SecurityService _securityService;

  Future<String?> call({
    required String userID,
    required String filePath,
  }) async {
    try {
      final file = File(filePath);

      // 1. Dosya varlık kontrolü
      if (!file.existsSync()) {
        throw Exception('Dosya bulunamadı: $filePath');
      }

      final isSafe = await _securityService.isImageSafe(file);

      if (!isSafe) {
        throw Exception(
          'Image has unsafe content! Please contact us if there is any mistake.',
        );
      }

      final path =
          '${FileService.privateUsers}$userID/community/images/community_info.jpg';

      final downloadUrl = await _fileService.uploadFile(file, path);

      return downloadUrl;
    } catch (e) {
      _loggingService.error('Profil resmi yüklenirken hata oluştu: $e');
      rethrow;
    }
  }
}
