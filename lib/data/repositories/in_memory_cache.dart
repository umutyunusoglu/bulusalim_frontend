import 'dart:collection';

class InMemoryCache<T> {
  InMemoryCache({required this.cacheSizeLimit});

  final LinkedHashMap<String, T> _cache = LinkedHashMap<String, T>();
  final int cacheSizeLimit;

  T? get(String key) {
    if (!_cache.containsKey(key)) return null;

    final value = _cache[key] as T;

    _cache.remove(key);
    _cache[key] = value; // LRU Update
    return value;
  }

  void set(String key, T value) {
    if (_cache.containsKey(key)) {
      //LRU Update
      _cache.remove(key);
    } else if (_cache.length >= cacheSizeLimit) {
      final oldestKey = _cache.keys.first;
      _cache.remove(oldestKey);
    }

    _cache[key] = value;
  }

  void clear() {
    _cache.clear();
  }
}
