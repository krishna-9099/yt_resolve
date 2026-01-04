// lib/normalize/format_normalizer.dart
// yt_resolve — Normalization layer (yt-dlp style)
//
// Goal:
// - Drop formats that are *technically valid* but *practically unplayable*
// - Normalize before scoring

import '../model/format.dart';
import '../engine/target.dart';
import '../clients/base_client.dart';
import 'ip_family.dart';

class FormatNormalizer {
  static List<Format> normalize(
    List<Format> formats, {
    required PlaybackTarget target,
    required BaseClient client,
  }) {
    final filtered = formats
        .where((f) => _passesCpsRule(f, target))
        .where((f) => _passesAndroidRule(f, target, client))
        .where((f) => _passesIpFamilyRule(f))
        .toList();

    // Dedupe by itag: prefer non-deciphered formats, otherwise prefer deciphered.
    return _dedupeByItag(filtered);
  }

  static List<Format> _dedupeByItag(List<Format> formats) {
    final Map<int, List<Format>> groups = {};
    for (final f in formats) {
      groups.putIfAbsent(f.itag, () => []).add(f);
    }

    final out = <Format>[];
    for (final entry in groups.entries) {
      final list = entry.value;

      // Prefer non-deciphered formats first
      final nonDeciphered = list.where((f) => !f.deciphered).toList();
      if (nonDeciphered.isNotEmpty) {
        // choose the highest bitrate among non-deciphered
        nonDeciphered.sort((a, b) => b.bitrate.compareTo(a.bitrate));
        out.add(nonDeciphered.first);
        continue;
      }

      // Otherwise choose deciphered formats (highest bitrate)
      list.sort((a, b) => b.bitrate.compareTo(a.bitrate));
      out.add(list.first);
    }

    return out;
  }

  // ---------------------------------------------------------------------------
  // Rule 1: cps (client playback state)
  // ---------------------------------------------------------------------------
  // cps > 0 = stateful session (bad for mpv)

  static bool _passesCpsRule(Format f, PlaybackTarget target) {
    if (target != PlaybackTarget.mpv) return true;

    // cps is encoded in URL if present
    final uri = Uri.parse(f.url);
    final cps = uri.queryParameters['cps'];

    if (cps == null) return true;
    return cps == '0';
  }

  // ---------------------------------------------------------------------------
  // Rule 2: ANDROID client filtering
  // ---------------------------------------------------------------------------
  // ANDROID video formats are hostile to desktop players

  static bool _passesAndroidRule(
    Format f,
    PlaybackTarget target,
    BaseClient client,
  ) {
    if (target != PlaybackTarget.mpv) return true;

    if (client.name.startsWith('ANDROID')) {
      // Only allow audio-only from ANDROID
      return f.audioOnly;
    }

    return true;
  }

  // ---------------------------------------------------------------------------
  // Rule 3: IP family matching
  // ---------------------------------------------------------------------------
  // IPv4-bound URLs fail on IPv6 networks and vice versa

  static bool _passesIpFamilyRule(Format f) {
    final uri = Uri.parse(f.url);
    final ip = uri.queryParameters['ip'];

    if (ip == null) return true;

    final urlFamily = IpFamilyUtil.fromIp(ip);
    final localFamily = IpFamilyUtil.local();

    return urlFamily == null || urlFamily == localFamily;
  }
}
