import 'package:test/test.dart';
import 'package:yt_resolve/cipher/js_parser.dart';

void main() {
  test('computed property call is detected', () {
    final js = """
var H={x:function(a){a.splice(0,3);} };function sig(a){H['x'](a,3);}""";
    final actions = JsParser.parseActions(js);
    expect(actions.isNotEmpty, true);
    expect(actions.first.type, equals(ActionType.splice));
    expect(actions.first.arg, equals(3));
  });

  test('wrapper function forwarded call is detected', () {
    final js = """
var H={r:function(a){a.reverse();}};function w(a){return H.r(a);} function sig(a){w(a);}""";
    final actions = JsParser.parseActions(js);
    expect(actions.isNotEmpty, true);
    expect(actions.first.type, equals(ActionType.reverse));
  });

  test('member alias call is detected', () {
    final js = """
var H={s:function(a){a.splice(0,2);} };var c = H['s'];function sig(a){c(a,2);}""";
    final actions = JsParser.parseActions(js);
    expect(actions.isNotEmpty, true);
    expect(actions.first.type, equals(ActionType.splice));
    expect(actions.first.arg, equals(2));
  });
}
