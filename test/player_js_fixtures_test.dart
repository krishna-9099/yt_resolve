import 'dart:io';

import 'package:test/test.dart';
import 'package:yt_resolve/yt_resolve.dart';

void main() {
  final fixtures = [
    'test/fixtures/player_js/base-638ec5c6.js',
    'test/fixtures/player_js/base-5ec65609.js',
    'test/fixtures/player_js/base-3d3ba064.js',
  ];

  for (final path in fixtures) {
    test('JsParser parses actions from $path and decipher changes signature', () {
      final js = File(path).readAsStringSync();

      final actions = JsParser.parseActions(js);
      expect(actions.isNotEmpty, isTrue, reason: 'Expected non-empty actions for $path');

      final input = '0123456789';
      final out = const Signature().decipherWithJs(input, js);
      expect(out, isNot(equals(input)), reason: 'Expected deciphered signature to change for $path');
    });
  }
}
