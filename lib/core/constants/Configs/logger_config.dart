import 'package:logger/web.dart';

final loggerPrettyPrinterConfig = PrettyPrinter(
  methodCount: 3, // Number of method calls to be displayed
  errorMethodCount: 10, // Number of method calls if stacktrace is provided
  dateTimeFormat: DateTimeFormat.onlyTimeAndSinceStart,
);
