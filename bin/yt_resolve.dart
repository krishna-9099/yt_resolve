import 'package:yt_resolve/engine/target.dart';
import 'package:yt_resolve/yt_resolve.dart';

Future<void> main(List<String> args) async {
  final resolver = YtResolve();
  final videoId = args.isNotEmpty ? args[0] : 'dQw4w9WgXcQ';

  final stream = await resolver.resolve(
    videoId: videoId,
    target: PlaybackTarget.mpv,
  );
  print(stream.url);
}
