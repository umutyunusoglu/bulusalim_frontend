import 'dart:collection';

class InMemoryCache<T> {
  InMemoryCache({required this.cacheSizeLimit, required this.ttl});

  final LinkedHashMap<String, CacheEntry<T>> _cache =
      LinkedHashMap<String, CacheEntry<T>>();

  final int cacheSizeLimit;
  final Duration ttl;

  T? get(String key) {
    if (!_cache.containsKey(key)) return null;

    final entry = _cache[key];
    if (entry == null) return null;

    if (DateTime.now().difference(entry.timestamp) > ttl) {
      _cache.remove(key);
      return null;
    }

    _cache.remove(key);
    _cache[key] = entry; // LRU Update
    return entry.value;
  }

  void set(String key, T value) {
    if (_cache.containsKey(key)) {
      //LRU Update
      _cache.remove(key);
    } else if (_cache.length >= cacheSizeLimit) {
      final oldestKey = _cache.keys.first;
      _cache.remove(oldestKey);
    }

    _cache[key] = CacheEntry(value, DateTime.now());
  }

  bool containsKey(String key) {
    return _cache.containsKey(key);
  }

  void clear() {
    _cache.clear();
  }

  void remove(String key) {
    _cache.remove(key);
  }

  List<T> get values {
    final now = DateTime.now();
    // Süresi dolanları temizleyerek sadece geçerli olanları döndür
    _cache.removeWhere((_, entry) => now.difference(entry.timestamp) > ttl);
    return _cache.values.map((e) => e.value).toList();
  }
}

class CacheEntry<T> {
  CacheEntry(this.value, this.timestamp);

  final T value;
  final DateTime timestamp;
}
