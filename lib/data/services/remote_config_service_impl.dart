import 'dart:convert';
import 'package:bulusalim/application/providers/get_it_init.dart';
import 'package:bulusalim/core/constants/Configs/app_config.dart';
import 'package:bulusalim/domain/services/remote_config_service.dart';
import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter/services.dart';

class RemoteConfigServiceImpl implements RemoteConfigService {
  RemoteConfigServiceImpl() : _remoteConfig = getIt<FirebaseRemoteConfig>();

  final FirebaseRemoteConfig _remoteConfig;

  @override
  Future<void> init() async {
    final jsonString = await rootBundle.loadString(
      AppConfig().remoteConfigDebugPath,
    );
    final defaults = json.decode(jsonString) as Map<String, dynamic>;
    await _remoteConfig.setConfigSettings(
      RemoteConfigSettings(
        // Timeout for fetching
        fetchTimeout: const Duration(seconds: 10),

        // Minimum interval between fetches
        minimumFetchInterval: const Duration(minutes: 5),
      ),
    );

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
    if (T == Map<String, dynamic>) {
      final jsonString = value.asString();
      return json.decode(jsonString) as T;
    }

    throw UnsupportedError('Type $T is not supported');
  }
}
