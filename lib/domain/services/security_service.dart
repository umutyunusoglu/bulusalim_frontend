import 'package:bulusalim/core/utils/types/types.dart';

abstract class SecurityService {
  Future<void> sendReport(
    ReportData reportData,
  );
  Future<void> blockUser(ReportData reportData);
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
