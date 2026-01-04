// ===============================
// lib/probe/http_probe.dart
// ===============================
import 'dart:io';
import '../model/stream.dart';

class HttpProbe {
  Future<bool> isPlayable(ResolvedStream stream) async {
    final client = HttpClient();
    try {
      final req = await client.getUrl(Uri.parse(stream.url));
      req.headers.set('Range', 'bytes=0-16383');
      final res = await req.close();
      return res.statusCode == 200 || res.statusCode == 206;
    } catch (_) {
      return false;
    } finally {
      client.close();
    }
  }
}
