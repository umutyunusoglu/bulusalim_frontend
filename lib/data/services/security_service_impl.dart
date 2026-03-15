import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/services.dart'
    show
        rootBundle; // Diğer yerlerde kullanmıyorsan silebilirsin, yeni paket assetleri kendi okuyor
import 'package:flutter_onnxruntime/flutter_onnxruntime.dart'; // YENİ PAKET EKLENDİ
import 'package:image/image.dart' as img;
import 'package:outnest/application/providers/get_it_init.dart';
import 'package:outnest/core/utils/logging/logging_service.dart';
import 'package:outnest/core/utils/types/types.dart';
import 'package:outnest/domain/entities/user/compact_user_entity.dart';
import 'package:outnest/domain/repositories/user_repository.dart';
import 'package:outnest/domain/services/security_service.dart';

class SecurityServiceImpl implements SecurityService {
  SecurityServiceImpl({
    required FirebaseFirestore firestore,
    required LoggingService logger,
    required FirebaseFunctions functions,
  }) : _firestore = firestore,
       _logger = logger,
       _functions = functions;

  final FirebaseFirestore _firestore;
  final LoggingService _logger;
  final FirebaseFunctions _functions;

  // ONNX Oturumu için değişkenler
  final OnnxRuntime _ort = OnnxRuntime();
  OrtSession? _session;

  @override
  Future<void> blockUser(ReportData reportData) async {
    final currentUserID = reportData.requestOwnerId;
    final reportedUserID = reportData.reportedUserId;

    if (currentUserID == null || reportedUserID == null) return;

    final userRepository = getIt<UserRepository>();

    final blockedUser = await userRepository.getUserPublicData(reportedUserID);
    if (blockedUser == null) return;

    await _firestore
        .collection('users')
        .doc(currentUserID)
        .collection('blockedUsers')
        .doc(reportedUserID)
        .set({
          'userID': blockedUser.userID,
          'username': blockedUser.username,
          'profileImageUrl': blockedUser.profileImageUrl,
        });

    _logger.info('User $reportedUserID has been blocked by $currentUserID.');
  }

  @override
  Future<void> sendReport(ReportData reportData) async {
    try {
      await blockUser(reportData);
      final callable = _functions.httpsCallable('reportUser');
      final result = await callable.call(<String, dynamic>{
        'reportedEntityID': reportData.reportedEntityId,
        'reportedEntityType': reportData.reportedEntityType,
        'reportedUserID': reportData.reportedUserId,
      });
      _logger.info('Report sent successfully: ${result.data}');
    } on FirebaseFunctionsException catch (e) {
      _logger.error('Report failed [${e.code}]: ${e.message}');
      if (e.code == 'resource-exhausted') {
        throw Exception(e.message ?? 'Çok sık rapor gönderiyorsunuz.');
      }
      throw Exception('Rapor gönderilemedi: ${e.message}');
    } catch (e) {
      _logger.error('Unexpected error during reporting: $e');
      throw Exception('Bir hata oluştu. Lütfen tekrar deneyin. ');
    }
  }

  @override
  Future<void> unblockUser(Identifier ownerID, Identifier blockedUserID) async {
    if (!await isUserBlocked(ownerID, blockedUserID)) {
      return;
    }
    await _firestore
        .collection('users')
        .doc(ownerID)
        .collection('blockedUsers')
        .doc(blockedUserID)
        .delete();
  }

  @override
  Future<List<CompactUserEntity>> getBlockedUsers(Identifier ownerID) async {
    final snapshot = await _firestore
        .collection('users')
        .doc(ownerID)
        .collection('blockedUsers')
        .get();

    return snapshot.docs
        .map(
          (doc) => CompactUserEntity(
            userID: doc['userID'] as String,
            username: doc['username'] as String,
            profileImageUrl: doc['profileImageUrl'] as String,
            university: null,
            nameSurname: null,
            isPrivate: null,
            bio: null,
            accountType: null,
            communityData: null,
          ),
        )
        .toList();
  }

  @override
  Future<bool> isUserBlocked(
    Identifier ownerID,
    Identifier queriedUserID,
  ) async {
    final doc = await _firestore
        .collection('users')
        .doc(ownerID)
        .collection('blockedUsers')
        .doc(queriedUserID)
        .get();

    return doc.exists;
  }

  // --- YENİ EKLENEN NSFW KONTROL KISMI ---

  /// Modeli hafızaya yükler.
  Future<void> _loadModel() async {
    if (_session != null) return;
    try {
      // flutter_onnxruntime paketinde model direkt asset'ten yüklenebiliyor
      _session = await _ort.createSessionFromAsset(
        'assets/nsfw/small_model.onnx',
      );
      _logger.info("NSFW Modeli başarıyla yüklendi.");
    } catch (e) {
      _logger.error("NSFW Modeli yüklenirken hata oluştu: $e");
    }
  }

  @override
  Future<bool> isImageSafe(File imageFile) async {
    try {
      // 1. Modeli yükle (Eğer yüklenmemişse)
      await _loadModel();
      if (_session == null) {
        _logger.warn("Model session is null, skipping check.");
        return true;
      }

      // 2. Resmi decode et
      final imageBytes = await imageFile.readAsBytes();
      final img.Image? originalImage = img.decodeImage(imageBytes);

      if (originalImage == null) {
        _logger.error("Resim dosyası okunamadı.");
        return false;
      }

      // 3. Resmi boyutlandır
      final resizedImage = img.copyResize(
        originalImage,
        width: 224,
        height: 224,
      );

      // 4. Preprocessing (Normalizasyon)
      const mean = [0.485, 0.456, 0.406];
      const std = [0.229, 0.224, 0.225];

      final Float32List inputFloats = Float32List(1 * 3 * 224 * 224);

      int pixelIndex = 0;
      for (int c = 0; c < 3; c++) {
        for (int y = 0; y < 224; y++) {
          for (int x = 0; x < 224; x++) {
            final pixel = resizedImage.getPixel(x, y);

            double channelValue;
            if (c == 0) {
              channelValue = pixel.r / 255.0;
            } else if (c == 1) {
              channelValue = pixel.g / 255.0;
            } else {
              channelValue = pixel.b / 255.0;
            }

            inputFloats[pixelIndex++] = (channelValue - mean[c]) / std[c];
          }
        }
      }

      // 5. Tensör oluştur (YENİ API)
      final inputOrt = await OrtValue.fromList(inputFloats, [1, 3, 224, 224]);

      // 6. Tahmini Çalıştır
      final inputs = {'pixel_values': inputOrt};
      final outputs = await _session!.run(inputs);

      // 7. Sonuçları Yorumla
      final outputValue = outputs.values.first;
      if (outputValue == null) {
        throw Exception("Model geçerli bir sonuç döndürmedi.");
      }

      final outputList = await outputValue.asList() as List;
      final scores = outputList[0] as List;

      // Temizlik (YENİ API)
      await inputOrt.dispose();
      for (final out in outputs.values) {
        if (out != null) await out.dispose();
      }

      final normalScore = (scores[0] as num).toDouble();
      final nsfwScore = (scores[1] as num).toDouble();

      _logger.info("NSFW Check: Normal=$normalScore, NSFW=$nsfwScore");

      if (nsfwScore > normalScore) {
        return false; // NOT SAFE
      }

      return true; // SAFE
    } catch (e) {
      _logger.error("NSFW kontrolü sırasında hata: $e");
      return true;
    }
  }

  @override
  Future<Map<String, double>> analyzeImageScores(File imageFile) async {
    try {
      await _loadModel();
      if (_session == null) return {'normal': 0.0, 'nsfw': 0.0};

      final imageBytes = await imageFile.readAsBytes();
      final img.Image? originalImage = img.decodeImage(imageBytes);
      if (originalImage == null) return {'normal': 0.0, 'nsfw': 0.0};

      final resizedImage = img.copyResize(
        originalImage,
        width: 224,
        height: 224,
      );
      const mean = [0.485, 0.456, 0.406];
      const std = [0.229, 0.224, 0.225];
      final Float32List inputFloats = Float32List(1 * 3 * 224 * 224);
      int pixelIndex = 0;
      for (int c = 0; c < 3; c++) {
        for (int y = 0; y < 224; y++) {
          for (int x = 0; x < 224; x++) {
            final pixel = resizedImage.getPixel(x, y);
            double channelValue;
            if (c == 0) {
              channelValue = pixel.r / 255.0;
            } else if (c == 1) {
              channelValue = pixel.g / 255.0;
            } else {
              channelValue = pixel.b / 255.0;
            }
            inputFloats[pixelIndex++] = (channelValue - mean[c]) / std[c];
          }
        }
      }

      // Tensör oluştur
      final inputOrt = await OrtValue.fromList(inputFloats, [1, 3, 224, 224]);
      final inputs = {'pixel_values': inputOrt};

      // Tahmini çalıştır
      final outputs = await _session!.run(inputs);

      // Sonucu al
      final outputValue = outputs.values.first;
      if (outputValue == null) return {'normal': 0.0, 'nsfw': 0.0};

      final outputList = await outputValue.asList() as List;
      final rawScores = outputList[0] as List;

      // Temizlik
      await inputOrt.dispose();
      for (final out in outputs.values) {
        if (out != null) await out.dispose();
      }

      double normalExp = exp((rawScores[0] as num).toDouble());
      double nsfwExp = exp((rawScores[1] as num).toDouble());
      double sumExp = normalExp + nsfwExp;

      return {
        'normal': normalExp / sumExp,
        'nsfw': nsfwExp / sumExp,
      };
    } catch (e) {
      _logger.error("Score analizi hatası: $e");
      return {'normal': 0.0, 'nsfw': 0.0};
    }
  }
}
