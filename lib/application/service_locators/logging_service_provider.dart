import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:outnest/core/utils/logging/logging_service.dart';
import 'package:outnest/core/utils/logging/logging_service_impl.dart';

Provider<LoggingService> loggingServiceProvider = Provider<LoggingService>(
  (ref) => LoggingServiceImpl(),
);
