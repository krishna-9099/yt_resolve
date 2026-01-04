import 'package:test/test.dart';
import 'package:yt_resolve/extract/formats_extractor.dart';
import 'package:yt_resolve/cipher/signature.dart';

void main() {
  test('deciphers signatureCipher with playerJs and attaches sig param', () {
    const playerJs = '''
      var Yz = {
        swap:function(a,b){var c=a[0];a[0]=a[b%a.length];a[b]=c},
        slice:function(a,b){return a.slice(b)},
        reverse:function(a){a.reverse()}
      };
      function sig(a){a=a.split('');Yz.swap(a,2);a=Yz.slice(a,1);Yz.reverse(a);return a.join('')}
    ''';

    const s = 'abcdefg';
    final expected = const Signature().decipherWithJs(s, playerJs);

    final cipherQuery = Uri(
      queryParameters: {
        'url': 'https://example.invalid/stream.mp4',
        's': s,
        'sp': 'sig',
      },
    ).query;

    final playerResponse = {
      'streamingData': {
        'adaptiveFormats': [
          {
            'itag': 1,
            'mimeType': 'video/mp4',
            'bitrate': 800,
            'signatureCipher': cipherQuery,
          },
        ],
      },
    };

    final formats = FormatsExtractor.extract(
      playerResponse,
      playerJs: playerJs,
    );
    expect(formats, isNotEmpty);
    final f = formats.first;
    final url = f.url;
    expect(url, contains('sig=${Uri.encodeQueryComponent(expected)}'));
    expect(f.deciphered, isTrue);
  });

  test('non-ciphered formats are not marked deciphered', () {
    final playerResponse = {
      'streamingData': {
        'adaptiveFormats': [
          {
            'itag': 2,
            'mimeType': 'video/mp4',
            'bitrate': 800,
            'url': 'https://example.invalid/plain.mp4',
          },
        ],
      },
    };

    final formats = FormatsExtractor.extract(playerResponse);
    expect(formats, isNotEmpty);
    expect(formats.first.deciphered, isFalse);
  });
}
