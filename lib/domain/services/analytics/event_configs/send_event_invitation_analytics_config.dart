import 'package:outnest/core/utils/types/types.dart';
import 'package:outnest/domain/services/analytics/analytics_constants.dart';

class SendEventInvitationAnalyticsConfig {
  SendEventInvitationAnalyticsConfig({
    required this.eventID,
    required this.toUserID,
  });

  Map<String, Object> toMap() {
    return {
      AnalyticsParams.eventID: eventID,
      AnalyticsParams.toUserID: toUserID,
    };
  }

  final Identifier eventID;
  final Identifier toUserID;
}
