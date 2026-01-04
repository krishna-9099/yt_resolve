// ===============================
// lib/extract/formats_extractor.dart
// ===============================
import '../model/format.dart';

import '../cipher/signature.dart';
import '../model/format.dart';

class FormatsExtractor {
  /// Extract formats, using [playerJs] to decipher ciphered signatures when present.
  static List<Format> extract(
    Map<String, dynamic> playerResponse, {
    String? playerJs,
  }) {
    final streamingData = playerResponse['streamingData'];
    if (streamingData == null) return [];

    final List formats = (streamingData['adaptiveFormats'] ?? []) as List;

    final out = <Format>[];

    for (final f in formats) {
      String? url = f['url'] as String?;

      // Handle ciphered signatures in `signatureCipher` or `cipher` fields
      final cipher = (f['signatureCipher'] ?? f['cipher']) as String?;
      if (url == null && cipher != null) {
        final query = Uri.splitQueryString(cipher);
        url = query['url'];
        final s = query['s'];
        final sp = query['sp'] ?? 'signature';

        if (url != null && s != null && playerJs != null) {
          final sig = const Signature().decipherWithJs(s, playerJs);
          final sep = url.contains('?') ? '&' : '?';
          url = '$url$sep$sp=${Uri.encodeQueryComponent(sig)}';
        }
      }

      if (url == null) continue;

      final mime = f['mimeType'] as String? ?? '';

      // Mark deciphered true when we synthesized the url using the player JS
      final wasDeciphered = (cipher != null && url != null && playerJs != null);

      out.add(
        Format(
          itag: f['itag'] ?? 0,
          mimeType: mime,
          bitrate: (f['bitrate'] ?? 0) as int,
          url: url,
          audioOnly: mime.startsWith('audio/'),
          deciphered: wasDeciphered,
        ),
      );
    }

    return out;
  }
}
