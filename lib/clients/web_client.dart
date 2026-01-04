import 'dart:convert';

import 'package:http/http.dart' as http;

import 'base_client.dart';

class WebClient extends BaseClient {
  final http.Client? httpClient;

  WebClient({this.httpClient});

  @override
  String get name => 'WEB';

  @override
  String get clientName => 'WEB';

  @override
  String get clientVersion => '2.20250101.00.00'; // update periodically

  @override
  bool get audioOnly => false;

  @override
  Map<String, String> get headers => const {
    'User-Agent': 'Mozilla/5.0 (X11; Linux x86_64)',
    'Accept-Language': 'en-US,en;q=0.9',
  };

  @override
  Future<Map<String, dynamic>> fetchPlayer(String videoId) async {
    final client = httpClient ?? http.Client();
    try {
      final uri = Uri.https('www.youtube.com', '/get_video_info', {
        'video_id': videoId,
        'html5': '1',
        'c': 'TVHTML5',
      });

      final resp = await client.get(uri, headers: headers);
      if (resp.statusCode != 200) throw Exception('HTTP ${resp.statusCode}');

      final body = resp.body;
      final trimmed = body.trimLeft();
      if (trimmed.startsWith('{') || trimmed.startsWith('[')) {
        return json.decode(body) as Map<String, dynamic>;
      }

      final m = RegExp(r'player_response=([^&]+)').firstMatch(body);
      if (m != null) {
        final encoded = m.group(1)!;
        final decoded = Uri.decodeQueryComponent(encoded);
        final parsed = json.decode(decoded) as Map<String, dynamic>;
        return parsed;
      }

      final map = <String, String>{};
      for (final part in body.split('&')) {
        final idx = part.indexOf('=');
        if (idx == -1) continue;
        final k = Uri.decodeQueryComponent(part.substring(0, idx));
        final v = Uri.decodeQueryComponent(part.substring(idx + 1));
        map[k] = v;
      }

      if (map.containsKey('player_response')) {
        final parsed =
            json.decode(map['player_response']!) as Map<String, dynamic>;
        return parsed;
      }

      throw Exception('player_response not found for $videoId');
    } finally {
      if (httpClient == null) client.close();
    }
  }
}
