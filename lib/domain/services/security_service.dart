import 'dart:io';

import 'package:outnest/core/utils/types/types.dart';
import 'package:outnest/domain/entities/user/compact_user_entity.dart';

abstract class SecurityService {
  Future<void> sendReport(
    ReportData reportData,
  );
  Future<void> blockUser(ReportData reportData);

  Future<void> unblockUser(Identifier ownerID, Identifier blockedUserID);

  Future<List<CompactUserEntity>> getBlockedUsers(Identifier ownerID);
  Future<bool> isUserBlocked(
    Identifier ownerID,
    Identifier queriedUserID,
  );
  Future<Map<String, double>> analyzeImageScores(File imageFile);
  Future<bool> isImageSafe(File imageFile);
}

class ReportData {
  ReportData({
    required this.reportedEntityId,
    required this.reportedEntityType,
    required this.reportedUserId,
    required this.requestOwnerId,
  });

  final Identifier requestOwnerId;
  final Identifier reportedUserId;
  final Identifier reportedEntityId;
  final String reportedEntityType;
}
