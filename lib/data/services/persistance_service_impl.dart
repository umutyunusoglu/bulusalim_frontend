import 'package:bulusalim/core/utils/logging/logging_service.dart';
import 'package:bulusalim/domain/services/persistance_service.dart';
import 'package:hive_flutter/hive_flutter.dart';

class PersistanceServiceImpl implements PersistanceService {
  PersistanceServiceImpl({
    required LoggingService logger,
    required Box<dynamic> box,
  }) : _logger = logger,
       _box = box;

  final LoggingService _logger;
  final Box<dynamic> _box;

  @override
  Future<void> saveString(String key, String value) async {
    try {
      await _box.put(key, value);
      _logger.info('Saved String: $key');
    } on Exception catch (e) {
      _logger.error('Error saving String ($key): $e');
      rethrow;
    }
  }

  @override
  Future<void> saveBool(String key, bool value) async {
    await _box.put(key, value);
  }

  @override
  Future<void> saveInt(String key, int value) async {
    await _box.put(key, value);
  }

  @override
  Future<void> saveJson(String key, Map<String, dynamic> json) async {
    try {
      await _box.put(key, json);
      _logger.info('Saved JSON: $key');
    } catch (e) {
      _logger.error('Error saving JSON ($key): $e');
      rethrow;
    }
  }

  @override
  Future<String?> getString(String key) async {
    // Hive okuması senkrondur ama interface asenkron olduğu için async keyword yeterli
    return _box.get(key) as String?;
  }

  @override
  Future<bool?> getBool(String key) async {
    return _box.get(key) as bool?;
  }

  @override
  Future<int?> getInt(String key) async {
    return _box.get(key) as int?;
  }

  @override
  Future<Map<String, dynamic>?> getJson(String key) async {
    final data = _box.get(key);

    if (data == null) return null;

    try {
      // GÜVENLİ DÖNÜŞÜM:
      // Hive'dan gelen Map<dynamic, dynamic>'i Map<String, dynamic>'e güvenle çevirir.
      return Map<String, dynamic>.from(data as Map);
    } on Exception catch (e) {
      _logger.error('Error casting JSON for key $key: $e');
      return null;
    }
  }

  @override
  Future<void> delete(String key) async {
    await _box.delete(key);
    _logger.info('Deleted key: $key');
  }

  @override
  Future<void> clearAll() async {
    await _box.clear();
    _logger.warn('Persistence Storage cleared completely.');
  }

  @override
  Future<bool> containsKey(String key) async {
    return _box.containsKey(key);
  }
}
