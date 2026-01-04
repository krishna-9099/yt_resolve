import 'package:http/http.dart' as http;

/// Simple in-memory cache for player JS fetched by URL.
class PlayerJsCache {
  final Map<String, String> _cache = {};
  final http.Client _http;

  PlayerJsCache({http.Client? httpClient})
    : _http = httpClient ?? http.Client();

  /// Fetches and caches the player JS at [url]. Subsequent calls return the cached content.
  Future<String> fetch(String url) async {
    final key = url;
    final cached = _cache[key];
    if (cached != null) return cached;

    final res = await _http.get(Uri.parse(url));
    if (res.statusCode != 200) {
      throw Exception('Failed to fetch player JS ($url): ${res.statusCode}');
    }

    _cache[key] = res.body;
    return res.body;
  }

  /// Returns the cached JS for [url] or null if not cached.
  String? get(String url) => _cache[url];

  /// Clears the in-memory cache.
  void clear() => _cache.clear();
}
