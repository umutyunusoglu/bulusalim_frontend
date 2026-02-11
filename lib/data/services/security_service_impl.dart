import 'package:outnest/application/providers/get_it_init.dart';
import 'package:outnest/core/utils/logging/logging_service.dart';
import 'package:outnest/core/utils/types/types.dart';
import 'package:outnest/domain/entities/user/compact_user_entity.dart';
import 'package:outnest/domain/repositories/user_repository.dart';
import 'package:outnest/domain/services/security_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';

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

  @override
  Future<void> blockUser(ReportData reportData) async {
    final currentUserID = reportData.requestOwnerId;
    final reportedUserID = reportData.reportedUserId;

    if (reportedUserID == null) return;

    final userRepository = getIt<UserRepository>();
    final blockedUser = await userRepository.getUser(reportedUserID);
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
            university: '',
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
}
