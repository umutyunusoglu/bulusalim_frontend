abstract class PersistanceService {
  Future<void> saveString(String key, String value);
  Future<void> saveBool(String key, bool value);
  Future<void> saveInt(String key, int value);

  Future<void> saveJson(String key, Map<String, dynamic> json);

  Future<String?> getString(String key);
  Future<bool?> getBool(String key);
  Future<int?> getInt(String key);

  Future<Map<String, dynamic>?> getJson(String key);

  Future<void> delete(String key);
  Future<void> clearAll();

  Future<bool> containsKey(String key);
}
