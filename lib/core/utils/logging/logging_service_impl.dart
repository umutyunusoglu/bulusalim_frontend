import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:logger/logger.dart';
import 'package:outnest/core/constants/configs/logger_config.dart'
    show loggerPrettyPrinterConfig;
import 'package:outnest/core/utils/logging/logging_service.dart';

class LoggingServiceImpl implements LoggingService {
  final _logger = Logger(printer: loggerPrettyPrinterConfig);
  final _crashlytics = FirebaseCrashlytics.instance;

  @override
  void debug(String message) {
    _logger.d(message);
    if (!kDebugMode) _crashlytics.log('[DEBUG] $message');
  }

  @override
  void error(String message, {Object? error, StackTrace? stackTrace}) {
    _logger.e(message, error: error, stackTrace: stackTrace);
    if (!kDebugMode) {
      _crashlytics.recordError(
        error ?? message,
        stackTrace,
        reason: message,
        fatal: false,
      );
    }
  }

  @override
  void fatal(String message, {Object? error, StackTrace? stackTrace}) {
    _logger.f(message, error: error, stackTrace: stackTrace);
    if (!kDebugMode) {
      _crashlytics.recordError(
        error ?? message,
        stackTrace,
        reason: message,
        fatal: true,
      );
    }
  }

  @override
  void info(String message) {
    _logger.i(message);
    if (!kDebugMode) _crashlytics.log('[INFO] $message');
  }

  @override
  void trace(String message) {
    _logger.t(message);
    // trace çok detaylı, Crashlytics'e gönderme
  }

  @override
  void warn(String message) {
    _logger.w(message);
    if (!kDebugMode) _crashlytics.log('[WARN] $message');
  }
}
