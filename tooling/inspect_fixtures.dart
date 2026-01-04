import 'dart:io';
import 'package:yt_resolve/cipher/js_parser.dart';

void main(){
  final fixtures = [
    'test/fixtures/player_js/base-638ec5c6.js',
    'test/fixtures/player_js/base-5ec65609.js',
    'test/fixtures/player_js/base-3d3ba064.js',
  ];
  for(final p in fixtures){
    print('--- $p ---');
    final js = File(p).readAsStringSync();
    final actions = JsParser.parseActions(js);
    print('actions: ${actions.length}');
    if (actions.isNotEmpty) print(actions);
    // quick heuristics checks
    print('contains String.fromCharCode: ${js.contains('String.fromCharCode(')}');
    print("contains bracket access ['] : ${js.contains("['")}");

    final cand = RegExp(r'(?:var|let|const)\s+([A-Za-z0-9_\$]+)\s*=\s*\{([\s\S]{0,2000}?)\}\s*;', multiLine: true, dotAll: true);
    var i=0;
    for(final m in cand.allMatches(js)){
      print('CAND #${++i} name=${m.group(1)} bodySnippet=${m.group(2)?.substring(0, m.group(2)!.length>120?120:m.group(2)!.length).replaceAll('\n',' ')}');
    }
    print('--- end ---\n');
  }
}
