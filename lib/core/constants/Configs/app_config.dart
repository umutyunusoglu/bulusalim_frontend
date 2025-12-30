import 'dart:io';

import 'package:flutter/foundation.dart';

class AppConfig {
  static final host = kIsWeb
      ? 'localhost'
      : Platform.isAndroid
      ? '10.0.2.2'
      : 'localhost';

  static const maxUserPhotos = 3;

  final remoteConfigDebugPath = 'assets/remote_config_defaults.json';

  static const int feedCacheSizeLimit = 10000;
  static const Duration postCacheTTL = Duration(minutes: 2);
  static const Duration feedCacheTTL = Duration(minutes: 2);

  static const int feedBatchSize = 40;
  static const int feedIDListSize = 1000;
  static const int feedFetchThreshold = 20;
  static const int feedWarmupTurns = 5;

  static const int maxPostCaptionLength = 50;

  static const String hiveBoxName = 'app_data_box';
}
