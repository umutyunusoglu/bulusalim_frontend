import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:outnest/core/utils/logging/logging_service.dart';
import 'package:outnest/domain/services/analytics/analytics_service.dart';

class AnalyticsServiceImpl extends AnalyticsService {
  final FirebaseAnalytics _analytics;
  final LoggingService _logger;

  AnalyticsServiceImpl({
    required FirebaseAnalytics analytics,
    required LoggingService logger,
  }) : _analytics = analytics,
       _logger = logger {
    FirebaseAnalytics.instance.setAnalyticsCollectionEnabled(true);
  }

  @override
  Future<void> logAnalytic(
    Comparable<String> eventName,
    Map<String, Object?> parameters,
  ) async {
    try {
      await _analytics.logEvent(
        name: eventName.toString(),
        parameters: parameters.map(
          (key, value) => MapEntry(key, value ?? 'null'),
        ),
      );
    } on FirebaseException catch (e) {
      // Handle Firebase-specific exceptions
      _logger.error('FirebaseException while logging analytics: ${e.message}');
    } catch (e) {
      // Handle any other exceptions
      _logger.error('Exception while logging analytics: $e');
    }
  }
}
