import 'package:test/test.dart';
import 'package:yt_resolve/normalize/format_normalizer.dart';
import 'package:yt_resolve/model/format.dart';
import 'package:yt_resolve/clients/base_client.dart';
import 'package:yt_resolve/engine/target.dart';

class DummyClient extends BaseClient {
  @override
  String get name => 'DUMMY';

  @override
  String get clientName => 'DUMMY';

  @override
  String get clientVersion => '0';

  @override
  Map<String, String> get headers => {};

  @override
  bool get audioOnly => false;

  @override
  Future<Map<String, dynamic>> fetchPlayer(String videoId) async => {};
}

void main() {
  test('prefers non-deciphered format when duplicate itag exists', () {
    final f1 = Format(
      itag: 1,
      mimeType: 'video/mp4',
      bitrate: 500,
      url: 'https://a.test/1.mp4',
      deciphered: true,
    );
    final f2 = Format(
      itag: 1,
      mimeType: 'video/mp4',
      bitrate: 400,
      url: 'https://b.test/1.mp4',
      deciphered: false,
    );

    final out = FormatNormalizer.normalize(
      [f1, f2],
      target: PlaybackTarget.mpv,
      client: DummyClient(),
    );

    expect(out.length, equals(1));
    expect(out.first.deciphered, isFalse);
    expect(out.first.url, contains('b.test'));
  });

  test('uses deciphered format when no original present', () {
    final f1 = Format(
      itag: 2,
      mimeType: 'video/mp4',
      bitrate: 300,
      url: 'https://x.test/2.mp4',
      deciphered: true,
    );

    final out = FormatNormalizer.normalize(
      [f1],
      target: PlaybackTarget.mpv,
      client: DummyClient(),
    );

    expect(out.length, equals(1));
    expect(out.first.deciphered, isTrue);
    expect(out.first.url, contains('x.test'));
  });
}
