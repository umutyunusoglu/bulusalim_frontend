import 'dart:io';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:image/image.dart' as img;
import 'package:outnest/application/providers/get_it_init.dart';
import 'package:outnest/core/utils/logging/logging_service.dart';
import 'package:outnest/core/utils/types/types.dart';
import 'package:outnest/domain/entities/user/compact_user_entity.dart';
import 'package:outnest/domain/repositories/user_repository.dart';
import 'package:outnest/domain/services/security_service.dart';
import 'package:tflite_flutter/tflite_flutter.dart';

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

  Future<void> initModel() async {
    try {
      _nswfImageModel = await Interpreter.fromAsset('assets/nsfw/model.tflite');

      _logger.info('NSFW Modeli başarıyla yüklendi.');
    } catch (e) {
      _logger.error('NSFW Modeli yüklenirken hata oluştu: $e');
    }
  }

  @override
  Future<void> blockUser(ReportData reportData) async {
    final currentUserID = reportData.requestOwnerId;
    final reportedUserID = reportData.reportedUserId;

    if (currentUserID == null || reportedUserID == null) return;

    final userRepository = getIt<UserRepository>();
    final blockedUser = await userRepository.getCurrentUser(reportedUserID);
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
      // 1. Önce kullanıcıyı engelle (Local işlem)
      await blockUser(reportData);

      // 2. Fonksiyonu çağır
      final callable = _functions.httpsCallable('reportUser');

      final result = await callable.call(<String, dynamic>{
        'reportedEntityID': reportData.reportedEntityId,
        'reportedEntityType': reportData.reportedEntityType,
        'reportedUserID': reportData.reportedUserId,
        // requestOwnerID'yi client'tan göndermeye gerek yok,
        // Cloud Function bunu request.auth.uid'den güvenli şekilde alıyor.
      });

      _logger.info('Report sent successfully: ${result.data}');
    } on FirebaseFunctionsException catch (e) {
      // Cloud Function'dan fırlatılan HttpsError'ları burada yakalıyoruz
      _logger.error('Report failed [${e.code}]: ${e.message}');

      // Eğer rate limit hatasıysa (resource-exhausted)
      if (e.code == 'resource-exhausted') {
        // Burada UI tarafına bir hata fırlatabilir veya bir Exception döndürebilirsin
        throw Exception(e.message ?? 'Çok sık rapor gönderiyorsunuz.');
      }

      throw Exception('Rapor gönderilemedi: ${e.message}');
    } catch (e) {
      // Beklenmedik diğer hatalar (İnternet kaybı vb.)
      _logger.error('Unexpected error during reporting: $e');
      throw Exception('Bir hata oluştu. Lütfen tekrar deneyin. ');
    }
  }

  @override
  Future<void> unblockUser(
    Identifier ownerID,
    Identifier blockedUserID,
  ) async {
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
            fullname: null,
            isPrivate: null,
            bio: null,
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

  Future<bool> isImageSafe(File imageFile) async {
    try {
      if (_nswfImageModel == null) await initModel();

      // 1. Görseli decode et ve 224x224 boyutuna getir
      final rawBytes = await imageFile.readAsBytes();
      final image = img.decodeImage(rawBytes);
      if (image == null) return false;

      final resizedImage = img.copyResize(image, width: 224, height: 224);

      // 2. Görseli modelin beklediği Float32 formatına dönüştür
      final Float32List inputAsFloat = _preprocessImage(resizedImage);

      // 2. ÖNEMLİ: Veriyi [1, 224, 224, 3] şekline sok
      // Float32List'i modelin beklediği 4 boyutlu yapıya zorluyoruz
      final input = inputAsFloat.reshape([1, 224, 224, 3]);

      // 3. Çıktı kısmını da reshape et
      var output = List<double>.filled(4, 0).reshape([1, 4]);

      // 4. Modeli çalıştır
      _nswfImageModel!.run(input, output);

      // 5. Sonuçları analiz et
      final List<double> scores = (output[0] as List<dynamic>).cast<double>();
      final results = <String, double>{
        for (int i = 0; i < _labels.length; i++) _labels[i]: scores[i],
      };

      _logger.info('NSFW Skorları: $results');

      // Güvenlik Mantığı:
      // Porn skoru 0.4'ten büyükse veya Sexy skoru 0.8'den büyükse güvensiz kabul et.
      if (results['porn']! > 0.4 || results['sexy']! > 0.8) {
        _logger.warn('Güvensiz içerik tespit edildi.');
        return false;
      }

      return true;
    } catch (e) {
      _logger.error('Görsel analizi sırasında hata: $e');
      return false; // Hata durumunda tedbirli davranıp false dönebiliriz
    }
  }

  /// Görseli [-1, 1] aralığında normalize ederek Float32List'e çevirir
  Float32List _preprocessImage(img.Image image) {
    final floatBuffer = Float32List(1 * 224 * 224 * 3);
    var pixelIndex = 0;

    for (var y = 0; y < 224; y++) {
      for (var x = 0; x < 224; x++) {
        final pixel = image.getPixel(x, y);

        // Manoj Bhor/MobileNetV2 standardı: (pixel - 127.5) / 127.5
        floatBuffer[pixelIndex++] = (pixel.r - 127.5) / 127.5;
        floatBuffer[pixelIndex++] = (pixel.g - 127.5) / 127.5;
        floatBuffer[pixelIndex++] = (pixel.b - 127.5) / 127.5;
      }
    }
    return floatBuffer;
  }

  void dispose() {
    _nswfImageModel?.close();
  }

  @override
  Interpreter? _nswfImageModel;

  @override
  final List<String> _labels = ['drawings', 'neutral', 'porn', 'sexy'];
}
