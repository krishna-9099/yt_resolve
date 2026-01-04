import 'package:test/test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'dart:convert';

import 'package:yt_resolve/clients/web_client.dart';

void main() {
  test('WebClient parses player_response from get_video_info', () async {
    final jsonBody = jsonEncode({
      'videoDetails': {'videoId': 'abc'},
    });
    final body =
        'status=ok&player_response=${Uri.encodeQueryComponent(jsonBody)}';
    final mock = MockClient((req) async {
      return http.Response(
        body,
        200,
        headers: {'content-type': 'application/x-www-form-urlencoded'},
      );
    });

    final client = WebClient(httpClient: mock);
    final map = await client.fetchPlayer('abc');
    expect(map['videoDetails']['videoId'], equals('abc'));
  });

  test('WebClient parses direct JSON body', () async {
    final jsonBody = jsonEncode({
      'videoDetails': {'videoId': 'xyz'},
    });
    final mock = MockClient(
      (req) async => http.Response(
        jsonBody,
        200,
        headers: {'content-type': 'application/json'},
      ),
    );

    final client = WebClient(httpClient: mock);
    final map = await client.fetchPlayer('xyz');
    expect(map['videoDetails']['videoId'], equals('xyz'));
  });
}
