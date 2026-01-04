/// Partial model for the playerResponse used by extractors.
class PlayerResponse {
  final Map<String, dynamic> raw;

  /// Optional raw text of the player JS (if fetched and cached by the fetcher)
  final String? playerJs;

  /// URL of the player JS that was used to fetch [playerJs]
  final String? playerJsUrl;

  PlayerResponse(this.raw, {this.playerJs, this.playerJsUrl});
}
