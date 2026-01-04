import 'package:test/test.dart';
import 'package:yt_resolve/yt_resolve.dart';
import 'package:yt_resolve/clients/base_client.dart';
import 'package:yt_resolve/model/format.dart';
import 'package:yt_resolve/engine/target.dart';

class FakePlayableClient extends BaseClient {
  @override
  String get name => 'FAKE';

  @override
  String get clientName => 'FAKE';

  @override
  String get clientVersion => '0';

  @override
  Map<String, String> get headers => {};

  @override
  bool get audioOnly => false;

  @override
  Future<Map<String, dynamic>> fetchPlayer(String videoId) async {
    return {
      'streamingData': {
        'adaptiveFormats': [
          {
            'itag': 1,
            'mimeType': 'video/mp4',
            'bitrate': 800,
            'url': 'https://example.invalid/yt/$videoId/playable.mp4',
          },
        ],
      },
    };
  }
}

void main() {
  test('resolve returns a ResolvedStream with url', () async {
    final resolver = YtResolve();
    final stream = await resolver.resolve(
      videoId: '6Mfe_tMuDfg',
      target: PlaybackTarget.mpv,
      clients: [FakePlayableClient()],
    );

    expect(stream, isNotNull);
    expect(stream.url, contains('6Mfe_tMuDfg'));
  });
}
