// core/init/hive_module.dart

import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get_it/get_it.dart';
import 'package:hive_flutter/hive_flutter.dart';

extension HiveModule on GetIt {
  Future<void> registerHive() async {
    await Hive.initFlutter();
    const secureStorage = FlutterSecureStorage();

    // --- Şifreleme Anahtarı Mantığı ---
    final keyString = await secureStorage.read(key: 'hive_key');
    List<int> encryptionKey;

    if (keyString == null) {
      encryptionKey = Hive.generateSecureKey();
      await secureStorage.write(
        key: 'hive_key',
        value: base64UrlEncode(encryptionKey),
      );
    } else {
      encryptionKey = base64Url.decode(keyString);
    }

    // --- Kutuyu Aç ---
    final box = await Hive.openBox<dynamic>(
      'app_data',
      encryptionCipher: HiveAesCipher(encryptionKey),
    );

    registerLazySingleton<Box<dynamic>>(() => box);
  }
}
