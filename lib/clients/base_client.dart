// ===============================
// lib/clients/base_client.dart
// ===============================
abstract class BaseClient {
  const BaseClient();

  String get name;
  String get clientName;
  String get clientVersion;

  /// Default headers for this client
  Map<String, String> get headers;

  /// Whether this client should return audio-only formats
  bool get audioOnly;

  /// Fetch player data for [videoId]. Implementations should return parsed
  /// JSON-like map representing the player response.
  Future<Map<String, dynamic>> fetchPlayer(String videoId);
}
