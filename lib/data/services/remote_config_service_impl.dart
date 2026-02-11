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

    final rawDefaults = json.decode(jsonString) as Map<String, dynamic>;

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
    // Verinin güncel olduğundan emin olmak için önce aktive edin (Opsiyonel ama garantidir)
    // await _remoteConfig.activate();

    final value = _remoteConfig.getValue(key);
    final rawString = value.asString();

    if (T == String) return rawString as T;
    if (T == int) return value.asInt() as T;
    if (T == double) return value.asDouble() as T;
    if (T == bool) return value.asBool() as T;

    if (T == Map || T == List) {
      // String boşsa veya null ise doğrudan boş koleksiyon dön
      if (rawString.trim().isEmpty) {
        return (T == List ? [] : {}) as T;
      }

      try {
        return json.decode(rawString) as T;
      } catch (e) {
        print('Remote Config Decode Hatası ($key): $e');
        return (T == List ? [] : {}) as T;
      }
    }

    throw UnsupportedError('Type $T is not supported');
  }
}
