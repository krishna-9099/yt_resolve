// ===============================
// lib/model/stream.dart
// ===============================
class ResolvedStream {
  ResolvedStream({
    required this.url,
    required this.itag,
    required this.mimeType,
    required this.client,
    required this.bitrate,
    this.expiresAt,
  });

  final String url;
  final int itag;
  final String mimeType;
  final String client;
  final int bitrate;
  final DateTime? expiresAt;
}
