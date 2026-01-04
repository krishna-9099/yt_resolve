import 'package:test/test.dart';
import 'package:yt_resolve/extract/player_fetcher.dart';
import 'package:yt_resolve/clients/base_client.dart';

class FakeClient extends BaseClient {
  final Map<String, dynamic> data;
  FakeClient(this.data) : super();

  @override
  String get clientName => 'FAKE';

  @override
  String get clientVersion => '0';

  @override
  String get name => 'FAKE';

  @override
  Map<String, String> get headers => {};

  @override
  bool get audioOnly => false;

  @override
  Future<Map<String, dynamic>> fetchPlayer(String videoId) async => data;
}

void main() {
  test('PlayerFetcher returns PlayerResponse wrapping client data', () async {
    final fake = FakeClient({'x': 1});
    final fetcher = PlayerFetcher(client: fake);
    final resp = await fetcher.fetch('id');
    expect(resp.raw['x'], equals(1));
  });
}
