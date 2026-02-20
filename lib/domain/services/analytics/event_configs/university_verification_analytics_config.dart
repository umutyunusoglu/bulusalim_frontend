import 'package:outnest/domain/services/analytics/analytics_constants.dart';

class UniversityVerificationAnalyticsConfig {
  UniversityVerificationAnalyticsConfig({
    required this.universityName,
    required this.success,
  });

  final String universityName;
  final bool success;

  Map<String, Object> toMap() {
    return {
      AnalyticsParams.universityName: universityName,
      AnalyticsParams.success: success,
    };
  }
}
