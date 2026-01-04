import 'package:yt_resolve/cipher/js_parser.dart';

void main(){
  const js = """
      var Yz = {
        swap:function(a,b){var c=a[0];a[0]=a[b%a.length];a[b]=c},
        slice:function(a,b){return a.slice(b)},
        reverse:function(a){a.reverse()},
        rot:function(a){a.push(a.shift())}
      };
      var n = 2;
      function sig(a){a=a.split('');Yz.swap(a,2);a=Yz.slice(a,1);Yz.reverse(a);Yz.rot(a);return a.join('')}
    """;
  // Inspect function bodies matched by our funcPatterns so we can see what the
  // parser sees as the signature function body.
  final funcPatterns = [
    RegExp(r'function\s+[A-Za-z0-9_\$]*\s*\([A-Za-z0-9_]+\)\s*\{([^}]*)\}', multiLine: true, dotAll: true),
    RegExp(r'[A-Za-z0-9_\$]+\s*=\s*function\s*\([A-Za-z0-9_]+\)\s*\{([^}]*)\}', multiLine: true, dotAll: true),
    RegExp(r'[A-Za-z0-9_\$]+\s*:\s*function\s*\([A-Za-z0-9_]+\)\s*\{([^}]*)\}', multiLine: true, dotAll: true),
  ];
  for (final pattern in funcPatterns) {
    for (final f in pattern.allMatches(js)) {
      final fb = f.group(1) ?? '';
      print('--- matched fbody ---');
      print(fb);
      print('--- end fbody ---');
    }
  }
  final actions = JsParser.parseActions(js);
  print(actions);
}
