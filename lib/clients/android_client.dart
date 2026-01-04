import 'base_client.dart';
import 'web_client.dart';

class AndroidClient extends BaseClient {
  const AndroidClient({this.audioOnly = false});

  @override
  final bool audioOnly;

  @override
  String get name => audioOnly ? 'ANDROID_AUDIO' : 'ANDROID';

  @override
  String get clientName => 'ANDROID';

  @override
  String get clientVersion => '18.11.34';

  @override
  Map<String, String> get headers => const {
    'User-Agent': 'com.google.android.youtube/18.11.34 (Linux; U; Android 13)',
    'Accept-Language': 'en-US,en;q=0.9',
  };

  @override
  Future<Map<String, dynamic>> fetchPlayer(String videoId) =>
      WebClient().fetchPlayer(videoId);
}
