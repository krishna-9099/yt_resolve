// ===============================
// lib/extract/player_fetcher.dart
// ===============================
import '../model/player_response.dart';
import '../clients/base_client.dart';
import '../clients/web_client.dart';
import '../cipher/js_cache.dart';

/// Fetches the playerResponse for a given videoId using a [BaseClient].
/// Optionally fetches and attaches the player JS via [PlayerJsCache].
class PlayerFetcher {
  final BaseClient _client;
  final PlayerJsCache _jsCache;

  PlayerFetcher({BaseClient? client, PlayerJsCache? jsCache})
    : _client = client ?? WebClient(),
      _jsCache = jsCache ?? PlayerJsCache();

  Future<PlayerResponse> fetch(String videoId) async {
    final raw = await _client.fetchPlayer(videoId);

    // Heuristics to find player JS URL in the player response
    String? jsUrl;
    if (raw['assets'] != null && raw['assets']['js'] != null) {
      jsUrl = raw['assets']['js'] as String;
    } else if (raw['playerUrl'] != null) {
      jsUrl = raw['playerUrl'] as String;
    }

    String? playerJs;
    if (jsUrl != null) {
      try {
        playerJs = await _jsCache.fetch(jsUrl);
      } catch (_) {
        // Ignore JS fetch failures — signature decipher will fallback
      }
    }

    return PlayerResponse(raw, playerJs: playerJs, playerJsUrl: jsUrl);
  }
}
