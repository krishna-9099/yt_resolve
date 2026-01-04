// ============================================================================
// lib/clients/ios_client.dart
// ============================================================================

import 'base_client.dart';

class IosClient extends BaseClient {
  const IosClient({this.audioOnly = false});

  @override
  final bool audioOnly;

  @override
  String get name => audioOnly ? 'IOS_AUDIO' : 'IOS';

  @override
  String get clientName => 'IOS';

  @override
  String get clientVersion => '19.09.3';

  @override
  Map<String, String> get headers => const {
    'User-Agent':
        'com.google.ios.youtube/19.09.3 (iPhone14,3; U; CPU iOS 17_0 like Mac OS X)',
    'Accept-Language': 'en-US,en;q=0.9',
  };

  /// iOS client is extremely sensitive to payload shape
  @override
  Map<String, dynamic> get contextOverrides => const {
    'client': {
      'deviceModel': 'iPhone14,3',
      'osName': 'iOS',
      'osVersion': '17.0',
      'hl': 'en',
      'gl': 'US',
    },
  };

  @override
  Future<Map<String, dynamic>> fetchPlayer(String videoId) {
    // TODO: implement fetchPlayer
    throw UnimplementedError();
  }
}
