// ===============================
// lib/model/format.dart
// ===============================
class Format {
  Format({
    required this.itag,
    required this.mimeType,
    required this.bitrate,
    required this.url,
    this.expiresAt,
    this.audioOnly = false,
    this.deciphered = false,
  });

  final int itag;
  final String mimeType;
  final int bitrate;
  final String url;
  final DateTime? expiresAt;
  final bool audioOnly;

  /// True when the URL was produced by deciphering a signature using player JS.
  final bool deciphered;

  @override
  String toString() =>
      'Format(itag: $itag, mime: $mimeType, bitrate: $bitrate, url: $url, deciphered: $deciphered)';
}
