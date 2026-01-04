import 'package:test/test.dart';
import 'package:yt_resolve/yt_resolve.dart';

void main() {
  test('signature decipher is noop by default', () {
    final sig = const Signature();
    expect(sig.decipher('abc'), equals('abc'));
  });

  test('js parser extracts and applies actions', () {
    const js = '''
      var Yz = {
        swap:function(a,b){var c=a[0];a[0]=a[b%a.length];a[b]=c},
        slice:function(a,b){return a.slice(b)},
        reverse:function(a){a.reverse()},
        rot:function(a){a.push(a.shift())}
      };
      var n = 2;
      function sig(a){a=a.split('');Yz.swap(a,2);a=Yz.slice(a,1);Yz.reverse(a);Yz.rot(a);return a.join('')}
    ''';

    final actions = JsParser.parseActions(js);
    expect(actions.length, equals(4));
    expect(actions[0].type, equals(ActionType.swap));
    expect(actions[0].arg, equals(2));
    expect(actions[1].type, equals(ActionType.slice));
    expect(actions[1].arg, equals(1));
    expect(actions[2].type, equals(ActionType.reverse));
    expect(actions[3].type, equals(ActionType.rotate));

    final out = const Signature().decipherWithJs('abcdefg', js);
    expect(out, equals('fedabg'));
  });

  test('inline reverse + splice(0,2)', () {
    const js = """
      function sig(a){a=a.split('');a.reverse();a.splice(0,2);return a.join('')}
    """;

    expect(const Signature().decipherWithJs('abcdefg', js), equals('edcba'));
  });

  test('n variable used in splice', () {
    const js = """
      var n = 2;
      function sig(a){a=a.split('');a.splice(0,n);return a.join('')}
    """;

    expect(const Signature().decipherWithJs('abcdefg', js), equals('cdefg'));
  });

  test('rotate using push(shift)', () {
    const js = """
      function sig(a){a=a.split('');a.push(a.shift());return a.join('')}
    """;

    expect(const Signature().decipherWithJs('abc', js), equals('bca'));
  });
}
