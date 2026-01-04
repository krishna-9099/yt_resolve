// ===============================
// lib/score/scorer.dart
// ===============================
import '../model/format.dart';
import '../engine/target.dart';

class FormatScorer {
  Format? pickBest(List<Format> formats, PlaybackTarget target) {
    if (formats.isEmpty) return null;

    formats.sort((a, b) => _score(b, target).compareTo(_score(a, target)));
    return formats.first;
  }

  int _score(Format f, PlaybackTarget target) {
    int score = 0;

    if (f.audioOnly) score += 100;
    if (f.mimeType.contains('opus')) score += 30;

    if (target == PlaybackTarget.mpv && !f.audioOnly) {
      score -= 100; // mpv prefers audio-only here
    }

    score += (f.bitrate ~/ 1000);
    return score;
  }
}
