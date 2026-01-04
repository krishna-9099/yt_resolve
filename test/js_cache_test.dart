import 'package:test/test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:yt_resolve/cipher/js_cache.dart';

void main() {
  test('fetches and caches player.js', () async {
    var calls = 0;
    final mock = MockClient((req) async {
      calls++;
      return http.Response(
        'console.log("player");',
        200,
        headers: {'content-type': 'application/javascript'},
      );
    });

    final cache = PlayerJsCache(httpClient: mock);
    final url = 'https://example.invalid/player.js';

    final first = await cache.fetch(url);
    final second = await cache.fetch(url);

    expect(first, contains('player'));
    expect(second, equals(first));
    expect(calls, equals(1));
  });

  test('throws on non-200 responses', () async {
    final mock = MockClient((req) async => http.Response('not found', 404));
    final cache = PlayerJsCache(httpClient: mock);

    await expectLater(
      cache.fetch('https://example.invalid/broken.js'),
      throwsException,
    );
  });
}
