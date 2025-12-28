import 'dart:io';

import 'package:flutter/foundation.dart';

String fixEmulatorUrl(String url) {
  if (kDebugMode && Platform.isAndroid && url.contains('localhost')) {
    return url.replaceFirst('localhost', '10.0.2.2');
  }
  return url;
}
