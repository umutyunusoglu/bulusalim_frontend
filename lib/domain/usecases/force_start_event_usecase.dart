import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:outnest/core/constants/configs/app_config.dart';
import 'package:outnest/core/utils/logging/logging_service.dart';
import 'package:outnest/domain/entities/feed/event/event_entity.dart';

class ForceStartEvent {
  ForceStartEvent({
    required LoggingService logger,
  }) : _logger = logger;

  final LoggingService _logger;
  Future<void> call(EventEntity currentEvent) async {
    try {
      _logger.info('Requesting force start for: ${currentEvent.eventID}');

      // Cloud Function'ı çağır
      final response = await http.post(
        Uri.parse(
          AppConfig.startEventUrl,
        ),
        body: jsonEncode({'eventId': currentEvent.eventID}),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        _logger.info('Event started by server.');
      }
    } catch (e) {
      _logger.error('Error: $e');
    }
  }
}
