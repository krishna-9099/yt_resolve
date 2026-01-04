import 'package:test/test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:yt_resolve/extract/player_fetcher.dart';
import 'package:yt_resolve/clients/base_client.dart';
import 'package:yt_resolve/cipher/js_cache.dart';

class FakeClientWithJs extends BaseClient {
  final String jsUrl;
  FakeClientWithJs(this.jsUrl);

  @override
  String get clientName => 'FAKE';

  @override
  String get clientVersion => '0';

  @override
  String get name => 'FAKE';

  @override
  Map<String, String> get headers => {};

  @override
  bool get audioOnly => false;

  @override
  Future<Map<String, dynamic>> fetchPlayer(String videoId) async {
    return {
      'assets': {'js': jsUrl},
      'streamingData': {'adaptiveFormats': []},
    };
  }
}

void main() {
  test('PlayerFetcher fetches and attaches player JS via cache', () async {
    var calls = 0;
    final mock = MockClient((req) async {
      calls++;
      return http.Response(
        'console.log("player js");',
        200,
        headers: {'content-type': 'application/javascript'},
      );
    });

    final cache = PlayerJsCache(httpClient: mock);
    final jsUrl = 'https://example.invalid/player.js';
    final client = FakeClientWithJs(jsUrl);

    final fetcher = PlayerFetcher(client: client, jsCache: cache);
    final resp = await fetcher.fetch('vid');

    expect(resp.playerJs, contains('player js'));
    expect(resp.playerJsUrl, equals(jsUrl));

    // second fetch should hit cache (no new HTTP call)
    final resp2 = await fetcher.fetch('vid');
    expect(resp2.playerJs, contains('player js'));
    expect(calls, equals(1));
  });

  test('PlayerFetcher tolerates missing player JS', () async {
    final client = FakeClientWithJs('https://example.invalid/missing.js');
    final mock = MockClient((req) async => http.Response('not found', 404));
    final cache = PlayerJsCache(httpClient: mock);
    final fetcher = PlayerFetcher(client: client, jsCache: cache);

    final resp = await fetcher.fetch('vid');
    expect(resp.playerJs, isNull);
    expect(resp.playerJsUrl, equals('https://example.invalid/missing.js'));
  });
}
