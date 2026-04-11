abstract class LoggingService {
  void debug(String message);
  void error(String message, {Object? error, StackTrace? stackTrace});
  void fatal(String message, {Object? error, StackTrace? stackTrace});
  void info(String message);
  void trace(String message);
  void warn(String message);
}
