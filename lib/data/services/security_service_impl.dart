import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/services.dart'
    show rootBundle; // Asset yüklemek için gerekli
import 'package:image/image.dart' as img; // Resim işleme paketi
import 'package:onnxruntime/onnxruntime.dart'; // ONNX Runtime
import 'package:outnest/application/service_locators/get_it_init.dart';
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

  // ONNX Oturumu için değişken
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
    // ... (Eski kodunuz aynı)
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
    // ... (Eski kodunuz aynı)
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
    // ... (Eski kodunuz aynı)
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
      // ONNX ortamını başlat
      OrtEnv.instance.init();

      // Model dosyasını assetlerden oku
      final rawAssetFile = await rootBundle.load(
        'assets/nsfw/small_model.onnx',
      );
      final bytes = rawAssetFile.buffer.asUint8List();

      final sessionOptions = OrtSessionOptions();
      _session = OrtSession.fromBuffer(bytes, sessionOptions);
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
        // Model yüklenemezse güvenli varsayıyoruz veya hata fırlatabiliriz.
        // False dönersek kullanıcı engellenir, True dönersek izin verilir.
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

      // 3. Resmi boyutlandır (ViT modelleri 224x224 ister)
      final resizedImage = img.copyResize(
        originalImage,
        width: 224,
        height: 224,
      );

      // 4. Preprocessing (Normalizasyon)
      // Python'daki ViTImageProcessor standart ImageNet değerlerini kullanır:
      // Mean: [0.485, 0.456, 0.406], Std: [0.229, 0.224, 0.225]
      const mean = [0.485, 0.456, 0.406];
      const std = [0.229, 0.224, 0.225];

      // Input Shape: [1, 3, 224, 224] -> Batch, Channels, Height, Width
      final Float32List inputFloats = Float32List(1 * 3 * 224 * 224);

      int pixelIndex = 0;
      // Kanal bazlı döngü (Önce tüm R'ler, sonra G'ler, sonra B'ler)
      for (int c = 0; c < 3; c++) {
        for (int y = 0; y < 224; y++) {
          for (int x = 0; x < 224; x++) {
            final pixel = resizedImage.getPixel(x, y);

            double channelValue;
            // image paketi v4.x pixel erişimi:
            if (c == 0)
              channelValue = pixel.r / 255.0;
            else if (c == 1)
              channelValue = pixel.g / 255.0;
            else
              channelValue = pixel.b / 255.0;

            // Normalize et: (value - mean) / std
            inputFloats[pixelIndex++] = (channelValue - mean[c]) / std[c];
          }
        }
      }

      // 5. Tensör oluştur
      final inputOrt = OrtValueTensor.createTensorWithDataList(
        inputFloats,
        [1, 3, 224, 224],
      );

      // 6. Tahmini Çalıştır
      final runOptions = OrtRunOptions();
      // Model input adı genelde 'pixel_values' olur, değilse onnx.config'den bakılır.
      // Falconsai modeli için genelde 'pixel_values'dur.
      final inputs = {'pixel_values': inputOrt};
      final outputs = _session!.run(runOptions, inputs);

      // 7. Sonuçları Yorumla
      // Çıktı: [[normal_score, nsfw_score]] (Logits)
      final outputList = outputs[0]?.value as List<List<double>>;
      final scores = outputList[0]; // İlk resmin skorları

      // Temizlik
      inputOrt.release();
      runOptions.release();
      // outputs için de release gerekebilir versiyona göre
      outputs.forEach((element) => element?.release());

      final normalScore = scores[0];
      final nsfwScore = scores[1];

      _logger.info("NSFW Check: Normal=$normalScore, NSFW=$nsfwScore");

      // Eğer NSFW skoru Normal skorundan büyükse GÜVENSİZ (False) döner.
      if (nsfwScore > normalScore) {
        return false; // NOT SAFE
      }

      return true; // SAFE
    } catch (e) {
      _logger.error("NSFW kontrolü sırasında hata: $e");
      // Hata durumunda ne yapılacağına karar verin.
      // Güvenlik kritikse false, UX kritikse true dönün.
      return true;
    }
  }

  @override
  Future<Map<String, double>> analyzeImageScores(File imageFile) async {
    try {
      await _loadModel(); // Önceki cevaptaki model yükleme fonksiyonu
      if (_session == null) return {'normal': 0.0, 'nsfw': 0.0};

      // --- isImageSafe içindeki görüntü işleme kodlarının aynısı buraya ---
      // (Kod tekrarını önlemek için görüntü işlemeyi ayrı bir private fonksiyona alabilirsiniz)
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
            if (c == 0)
              channelValue = pixel.r / 255.0;
            else if (c == 1)
              channelValue = pixel.g / 255.0;
            else
              channelValue = pixel.b / 255.0;
            inputFloats[pixelIndex++] = (channelValue - mean[c]) / std[c];
          }
        }
      }
      final inputOrt = OrtValueTensor.createTensorWithDataList(inputFloats, [
        1,
        3,
        224,
        224,
      ]);
      final runOptions = OrtRunOptions();
      final inputs = {'pixel_values': inputOrt};
      final outputs = _session!.run(runOptions, inputs);
      final outputList = outputs[0]?.value as List<List<double>>;
      final rawScores = outputList[0];

      inputOrt.release();
      runOptions.release();
      outputs.forEach((element) => element?.release());
      // --- Bitiş ---

      // SOFTMAX UYGULAMA (Logits -> Olasılık %)
      // Formül: e^x / sum(e^x)
      double normalExp = exp(rawScores[0]);
      double nsfwExp = exp(rawScores[1]);
      double sumExp = normalExp + nsfwExp;

      return {
        'normal': normalExp / sumExp, // Örn: 0.10
        'nsfw': nsfwExp / sumExp, // Örn: 0.90
      };
    } catch (e) {
      _logger.error("Score analizi hatası: $e");
      return {'normal': 0.0, 'nsfw': 0.0};
    }
  }
}
