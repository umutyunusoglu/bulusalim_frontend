import 'package:bulusalim/core/utils/logging/logging_service.dart';
import 'package:bulusalim/domain/services/security_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:dart_firebase_admin/firestore.dart' hide FieldValue;

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

    await _firestore
        .collection('users')
        .doc(currentUserID)
        .collection('blocked_users')
        .doc(reportedUserID)
        .set({
          'userID': reportedUserID,
          'blocked_at': FieldValue.serverTimestamp(),
        });

    _logger.info('User $reportedUserID has been blocked by $currentUserID.');
  }

  @override
  Future<void> sendReport(ReportData reportData) async {
    await blockUser(reportData);

    final callable = _functions.httpsCallable('reportUser');
    final result = await callable.call(<String, dynamic>{
      'reportedEntityID': reportData.reportedEntityId,
      'reportedEntityType': reportData.reportedEntityType,
      'reportedUserID': reportData.reportedUserId,
      'requestOwnerID': reportData.requestOwnerId,
    });

    _logger.info('Report sent: ${result.data}');
  }
}
