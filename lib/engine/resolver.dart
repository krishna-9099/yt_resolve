// lib/engine/resolver.dart
// yt_resolve – playability-first resolver (client rotation only)

import '../clients/base_client.dart';
import '../clients/web_client.dart';
import '../clients/android_client.dart';
import '../clients/tv_client.dart';
import '../model/format.dart';
import '../model/stream.dart';
import '../engine/target.dart';
import '../extract/player_fetcher.dart';
import '../extract/formats_extractor.dart';
import '../score/scorer.dart';
import '../probe/http_probe.dart';

/// Main resolver entry point.
///
/// Responsibilities:
/// - Rotate clients in the correct order
/// - Extract formats (no decipher yet)
/// - Normalize + score formats
/// - Perform lightweight playability check
/// - Fallback silently when a client fails
class YtResolve {
  YtResolve({HttpProbe? probe, FormatScorer? scorer})
    : _probe = probe ?? HttpProbe(),
      _scorer = scorer ?? FormatScorer();

  final HttpProbe _probe;
  final FormatScorer _scorer;

  /// Resolve a playable stream URL for a given video ID.
  Future<ResolvedStream> resolve({
    required String videoId,
    required PlaybackTarget target,
    List<BaseClient>? clients,
  }) async {
    final clientList = clients ?? _clientOrderFor(target);

    ResolvedStream? bestFallback;

    for (final client in clientList) {
      try {
        // 1️⃣ Fetch player response for this client
        final playerResponse = await PlayerFetcher(
          client: client,
        ).fetch(videoId);

        // 2️⃣ Extract raw formats (urls may still be ciphered later)
        final formats = FormatsExtractor.extract(
          playerResponse.raw,
          playerJs: playerResponse.playerJs,
        );

        if (formats.isEmpty) {
          _debug('No formats for client ${client.name}');
          continue;
        }

        // 3️⃣ Score & pick best format for this target
        final candidate = _scorer.pickBest(formats, target);

        if (candidate == null) {
          _debug('No suitable format for client ${client.name}');
          continue;
        }

        final stream = ResolvedStream(
          url: candidate.url,
          itag: candidate.itag,
          mimeType: candidate.mimeType,
          client: client.name,
          bitrate: candidate.bitrate,
          expiresAt: candidate.expiresAt,
        );

        // 4️⃣ Lightweight playability probe (GET + Range)
        final playable = await _probe.isPlayable(stream);

        if (playable) {
          _debug('Playable via client ${client.name}');
          return stream;
        }

        // Keep best fallback if nothing works
        bestFallback ??= stream;

        _debug('Probe failed for client ${client.name}, rotating…');
      } catch (e) {
        // 🔥 NEVER crash on one client
        _debug('Client ${client.name} failed: $e');
        continue;
      }
    }

    if (bestFallback != null) {
      _debug('Returning best fallback stream');
      return bestFallback;
    }

    throw ResolveException('No playable stream found for $videoId');
  }

  /// Decide client rotation order based on playback target.
  List<BaseClient> _clientOrderFor(PlaybackTarget target) {
    switch (target) {
      case PlaybackTarget.mpv:
        return [WebClient(), TvClient(), AndroidClient(audioOnly: true)];

      case PlaybackTarget.mobile:
        return [AndroidClient(audioOnly: false), WebClient()];
    }
  }

  void _debug(String message) {
    // Replace with proper logger if needed
    // ignore: avoid_print
    print('[yt_resolve] $message');
  }
}

class ResolveException implements Exception {
  ResolveException(this.message);
  final String message;

  @override
  String toString() => 'ResolveException: $message';
}
