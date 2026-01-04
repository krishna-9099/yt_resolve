/// Simple in-memory cache for small objects.
class MemoryCache<S, T> {
  final _map = <S, T>{};

  T? get(S key) => _map[key];
  void set(S key, T value) => _map[key] = value;
}
