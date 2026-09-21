import 'dart:collection';

/// A fast Least Recently Used (LRU) cache with a maximum capacity.
class LruCache<K, V> {
  final int maximumSize;
  final LinkedHashMap<K, V> _map = LinkedHashMap<K, V>();

  LruCache({this.maximumSize = 50});

  int get length => _map.length;
  bool get isEmpty => _map.isEmpty;
  bool get isNotEmpty => _map.isNotEmpty;
  Iterable<V> get values => _map.values;

  bool containsKey(K key) => _map.containsKey(key);

  V? get(K key) {
    final value = _map.remove(key);
    if (value != null) {
      _map[key] = value;
      return value;
    }
    return null;
  }

  V? operator [](K key) => get(key);

  void put(K key, V value) {
    _map.remove(key);
    if (_map.length >= maximumSize) {
      _map.remove(_map.keys.first);
    }
    _map[key] = value;
  }

  void operator []=(K key, V value) => put(key, value);

  V? remove(K key) => _map.remove(key);

  void clear() => _map.clear();
}
