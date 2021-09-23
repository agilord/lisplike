import 'package:jlp/jlp.dart';
import 'package:test/test.dart';

void main() {
  test('test run', () {
    final prog = '9 \x00 9.1 \x00 false \x00 "\'szoveg" ';
    final evl = parseProg(prog);
    final res = evl.run().toList();
    expect(res, [9, 9.1, false, 'szoveg']);
  });
  test('test add', () {
    final prog = '{"call": "add", "pars": {"rhs": 9.0, "lhs": 9.1}}';
    final evl = parseProg(prog);
    final res = evl.run().toList();
    expect(res, [18.1]);
  });
}
