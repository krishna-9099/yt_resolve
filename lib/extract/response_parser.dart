import '../model/player_response.dart';

/// Parses raw playerResponse into structured parts used by extractor.
class ResponseParser {
  const ResponseParser();

  // This is intentionally small for the scaffold.
  Map<String, dynamic> parse(PlayerResponse resp) => resp.raw;
}
