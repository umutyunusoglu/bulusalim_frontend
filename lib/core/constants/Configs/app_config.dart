import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:outnest/application/service_locators/get_it_init.dart';
import 'package:outnest/domain/services/remote_config_service.dart';

final DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();

class AppConfig {
  // Bu metodu main.dart dosyasında runApp'ten önce çağıracağız
  static Future<void> init() async {
    mapBoxAccessTokenKey = dotenv.env['MAPBOX_ACCESS_TOKEN'] ?? '';

    if (kIsWeb) {
      host = '127.0.0.1';
    } else if (Platform.isAndroid) {
      final deviceInfo = DeviceInfoPlugin();
      final androidInfo = await deviceInfo.androidInfo;
      isPhysicalDevice = androidInfo.isPhysicalDevice;
      debugPrint('Android isPhysicalDevice: $isPhysicalDevice');
      if (androidInfo.isPhysicalDevice) {
        host = '127.0.0.1'; //
      } else {
        host = '10.0.2.2';
      }
    } else if (Platform.isIOS) {
      host = '127.0.0.1';
    } else {
      // Diğer durumlar
      host = '127.0.0.1';
    }

    final remoteConfigService = getIt<RemoteConfigService>();
    categories = await remoteConfigService.getValue<Map>('categories').then((
      value,
    ) {
      return Map<String, String>.from(value);
    });

    try {
      isFeedPatternEnabled =
          await remoteConfigService.getValue<bool>('feed_pattern_enabled') ??
          false;
    } catch (e) {
      debugPrint('Remote Config hatası: $e');
      isFeedPatternEnabled = false;
    }
  }

  static late String host;
  static late Map<String, String> categories;
  static bool isPhysicalDevice = false;

  static const maxUserPhotos = 3;
  static const int eventCapacity = 20;
  static const int activePostDays = 1;

  final remoteConfigDebugPath = 'assets/remote_config_defaults.json';

  static const int feedCacheSizeLimit = 10000;
  static const Duration postCacheTTL = Duration(minutes: 2);
  static const Duration feedCacheTTL = Duration(minutes: 5);

  static const int feedBatchSize = 40;
  static const int feedIDListSize = 1000;
  static const int feedFetchThreshold = 20;
  static const int feedWarmupTurns = 5;

  static const int maxPostCaptionLength = 50;

  static const String hiveBoxName = 'app_data_box';

  static late String mapBoxAccessTokenKey;

  static late bool isFeedPatternEnabled;

  static const String baseUrl =
      'https://us-central1-bulusalim-e8e7c.cloudfunctions.net';
  static const String startEventEndpoint = '/startEventLogic';

  static String get startEventUrl => '$baseUrl$startEventEndpoint';
}
