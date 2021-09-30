import 'package:jlp/jlp.dart';
import 'package:test/test.dart';

void main() {
  /*
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
   */

  group('lisplike', () {
    test('add', () {
      final res = Evaluator(['add', 8, 9.1]).run();
      expect(res, 17.1);
    });

    test('multi-level add', () {
      final res = Evaluator([
        'add',
        ['add', 1, 7],
        [
          'add',
          ['add', 8, 1],
          0.1,
        ],
      ]).run();
      expect(res, 17.1);
    });

    test('list', () {
      final res = Evaluator(['list', 1, true, 'text']).run();
      expect(res, [1, true, 'text']);
    });

    test('multi-level list', () {
      final res = Evaluator([
        'list',
        1,
        true,
        ['list', 'text', 1.0],
      ]).run();
      expect(res, [
        1,
        true,
        ['text', 1.0]
      ]);
    });
  });
}
