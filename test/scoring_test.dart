import 'package:test/test.dart';
import 'package:yt_resolve/score/scorer.dart';
import 'package:yt_resolve/model/format.dart';
import 'package:yt_resolve/engine/target.dart';

void main() {
  test('scorer picks a best format', () {
    final scorer = FormatScorer();
    final f = Format(itag: 1, url: 'u', mimeType: 'video/mp4', bitrate: 1000);
    final best = scorer.pickBest([f], PlaybackTarget.mpv);
    expect(best, isNotNull);
  });
}
