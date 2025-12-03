import 'dart:io';

import 'package:flutter/foundation.dart';

class AppConfig {
  static final host = kIsWeb
      ? 'localhost'
      : Platform.isAndroid
      ? '10.0.2.2'
      : 'localhost';

  static final String functionsUrl =
      'http://$host:5001/bulusalim-e8e7c/us-central1/'; //TODO : MAKE IT ENVIRONMENT SPECIFIC AND SECURE

  static const maxUserPhotos = 3;

  final remoteConfigDebugPath = 'assets/remote_config_defaults.json';

  static const int feedCacheSizeLimit = 100;
  static const Duration postCacheTTL = Duration(minutes: 2);
  static const Duration feedCacheTTL = Duration(minutes: 2);

  static const int feedBatchSize = 40;
  static const int feedIDListSize = 1000;
  static const int feedFetchThreshold = 20;
}
