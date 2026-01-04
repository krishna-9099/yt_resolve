import 'dart:io';

import 'package:test/test.dart';
import 'package:yt_resolve/cipher/js_parser.dart';
import 'package:yt_resolve/cipher/signature.dart';

void main() {
  test('String.fromCharCode bracket access is detected', () {
    final js = """
var Q={m:function(a,b){a.splice(0,b);} };function sig(a){a=a.split("");Q[String.fromCharCode(109)](a,4);return a.join("");}
""";
    final actions = JsParser.parseActions(js);
    expect(actions.isNotEmpty, true);
    expect(actions.first.type, equals(ActionType.splice));
    expect(actions.first.arg, equals(4));

    final out = const Signature().decipherWithJs("0123456789", js);
    expect(out, isNot(equals("0123456789")));
  });

  test('Concatenated key bracket access is detected', () {
    final js = """
var O={sp:function(a,b){a.splice(0,b);} };function sig(a){a=a.split("");O['s'+'p'](a,2);return a.join("");}
""";
    final actions = JsParser.parseActions(js);
    expect(actions.isNotEmpty, true);
    expect(actions.first.type, equals(ActionType.splice));
    expect(actions.first.arg, equals(2));
  });

  test('Real fixture with computed key (fromCharCode) yields actions and transforms', () {
    final js = File('test/fixtures/player_js/computed-fromchar.js').readAsStringSync();
    final actions = JsParser.parseActions(js);
    expect(actions.isNotEmpty, true);
    final out = const Signature().decipherWithJs('0123456789', js);
    expect(out, isNot(equals('0123456789')));
  });
}
