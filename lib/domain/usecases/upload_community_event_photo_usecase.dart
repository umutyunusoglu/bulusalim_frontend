import 'dart:io';
import 'package:outnest/core/utils/logging/logging_service.dart';
import 'package:outnest/domain/services/file_service.dart';
import 'package:outnest/domain/services/security_service.dart';
import 'package:outnest/domain/services/session_service.dart';

class UploadCommunityEventPhoto {
  const UploadCommunityEventPhoto({
    required FileService fileService,
    required LoggingService loggingService,
    required SecurityService securityService,
    required SessionService sessionService,
  }) : _fileService = fileService,
       _loggingService = loggingService,
       _securityService = securityService,
       _sessionService = sessionService;

  final FileService _fileService;
  final LoggingService _loggingService;
  final SecurityService _securityService;
  final SessionService _sessionService;

  Future<String?> call({required String filePath}) async {
    try {
      final file = File(filePath);

      if (!file.existsSync()) {
        throw Exception('Dosya bulunamadı: $filePath');
      }

      final isSafe = await _securityService.isImageSafe(file);
      if (!isSafe) {
        throw Exception(
          'Image has unsafe content! Please contact us if there is any mistake.',
        );
      }

      final userID = _sessionService.currentUser!.userID;
      final uniqueId = '${userID}_${DateTime.now().millisecondsSinceEpoch}';
      final extension = filePath.split('.').last;

      final path = FileService.communityEventPhotoPath(
        uniqueId,
        'event_photo.$extension',
      );

      final downloadUrl = await _fileService.uploadFile(file, path);
      return downloadUrl;
    } catch (e) {
      _loggingService.error('Etkinlik fotoğrafı yüklenirken hata oluştu: $e');
      rethrow;
    }
  }
}
