import 'package:test/test.dart';
import 'package:yt_resolve/yt_resolve.dart';

void main() {
  test('package exports YtResolve', () {
    final r = YtResolve();
    expect(r, isNotNull);
  });
}
