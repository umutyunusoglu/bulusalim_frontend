import 'package:outnest/core/constants/configs/logger_config.dart'
    show loggerPrettyPrinterConfig;
import 'package:outnest/core/utils/logging/logging_service.dart';
import 'package:logger/logger.dart';

class LoggingServiceImpl implements LoggingService {
  final _logger = Logger(printer: loggerPrettyPrinterConfig);

  @override
  void debug(String message) {
    _logger.d(message);
  }

  @override
  void error(String message) {
    _logger.e(message);
  }

  @override
  void fatal(String message) {
    _logger.f(message);
  }

  @override
  void info(String message) {
    _logger.i(message);
  }

  @override
  void trace(String message) {
    _logger.t(message);
  }

  @override
  void warn(String message) {
    _logger.w(message);
  }
}
