// lib/data/services/remote_config_service_impl.dart

import 'dart:convert';
import 'package:outnest/application/providers/get_it_init.dart';
import 'package:outnest/core/constants/configs/app_config.dart';
import 'package:outnest/domain/services/remote_config_service.dart';
import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter/services.dart';

class RemoteConfigServiceImpl implements RemoteConfigService {
  RemoteConfigServiceImpl() : _remoteConfig = getIt<FirebaseRemoteConfig>();

  final FirebaseRemoteConfig _remoteConfig;

  @override
  Future<void> init() async {
    // 1. JSON dosyasını oku
    final jsonString = await rootBundle.loadString(
      AppConfig().remoteConfigDebugPath,
    );

    // 2. Ham veriyi Map olarak decode et
    final rawDefaults = json.decode(jsonString) as Map<String, dynamic>;

    // 3. ÖNEMLİ DÜZELTME:
    // Firebase Remote Config sadece String, int, bool, double kabul eder.
    // Eğer değer bir Map veya List ise, onu tekrar String'e (json.encode) çevirmeliyiz.

    final defaults = rawDefaults.map((key, value) {
      if (value is Map || value is List) {
        return MapEntry(key, json.encode(value));
      }
      return MapEntry(key, value);
    });

    await _remoteConfig.setConfigSettings(
      RemoteConfigSettings(
        fetchTimeout: const Duration(seconds: 10),
        minimumFetchInterval: const Duration(minutes: 5),
      ),
    );

    // Artık 'defaults' içindeki map_filters bir String olduğu için hata vermeyecek
    await _remoteConfig.setDefaults(defaults);
    await _remoteConfig.fetchAndActivate();
  }

  @override
  Future<T> getValue<T>(String key) async {
    final value = _remoteConfig.getValue(key);

    if (T == String) return value.asString() as T;
    if (T == int) return value.asInt() as T;
    if (T == double) return value.asDouble() as T;
    if (T == bool) return value.asBool() as T;

    // Map istersek String'i decode edip veriyoruz
    if (T == Map) {
      final jsonString = value.asString();
      // Eğer değer boş gelirse veya parse edilemezse boş map dön
      if (jsonString.isEmpty) return {} as T;
      return json.decode(jsonString) as T;
    }

    throw UnsupportedError('Type $T is not supported');
  }
} // import 'dart:convert';
// import 'package:outnest/application/providers/get_it_init.dart';
// import 'package:outnest/core/constants/configs/app_config.dart';
// import 'package:outnest/domain/services/remote_config_service.dart';
// import 'package:firebase_remote_config/firebase_remote_config.dart';
// import 'package:flutter/services.dart';

// class RemoteConfigServiceImpl implements RemoteConfigService {
//   RemoteConfigServiceImpl() : _remoteConfig = getIt<FirebaseRemoteConfig>();

//   final FirebaseRemoteConfig _remoteConfig;

//   @override
//   Future<void> init() async {
//     final jsonString = await rootBundle.loadString(
//       AppConfig().remoteConfigDebugPath,
//     );
//     final defaults = json.decode(jsonString) as Map<String, dynamic>;
//     await _remoteConfig.setConfigSettings(
//       RemoteConfigSettings(
//         // Timeout for fetching
//         fetchTimeout: const Duration(seconds: 10),

//         // Minimum interval between fetches
//         minimumFetchInterval: const Duration(minutes: 5),
//       ),
//     );

//     await _remoteConfig.setDefaults(defaults);
//     await _remoteConfig.fetchAndActivate();
//   }

//   @override
//   Future<T> getValue<T>(String key) async {
//     final value = _remoteConfig.getValue(key);

//     if (T == String) return value.asString() as T;
//     if (T == int) return value.asInt() as T;
//     if (T == double) return value.asDouble() as T;
//     if (T == bool) return value.asBool() as T;
//     if (T == Map) {
//       final jsonString = value.asString();
//       return json.decode(jsonString) as T;
//     }

//     throw UnsupportedError('Type $T is not supported');
//   }
// }
