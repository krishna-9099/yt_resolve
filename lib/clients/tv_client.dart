// ===============================
// lib/clients/tv_client.dart
// ===============================
import 'base_client.dart';
import 'web_client.dart';

class TvClient extends BaseClient {
  const TvClient();

  @override
  String get name => 'TVHTML5';

  @override
  String get clientName => 'TVHTML5';

  @override
  String get clientVersion => '7.20250101.00.00';

  @override
  bool get audioOnly => false;

  @override
  Map<String, String> get headers => const {
    'User-Agent': 'Mozilla/5.0 (SMART-TV; Linux; Tizen 6.0)',
    'Accept-Language': 'en-US,en;q=0.9',
  };

  @override
  Future<Map<String, dynamic>> fetchPlayer(String videoId) =>
      WebClient().fetchPlayer(videoId);
}
