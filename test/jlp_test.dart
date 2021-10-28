import 'dart:convert';

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
      final res = Evaluator().eval(['add', 8, 9.1]);
      expect(res, 17.1);
    });

    test('multi-level add', () {
      final res = Evaluator().eval([
        'add',
        ['add', 1, 7],
        [
          'add',
          ['add', 8, 1],
          0.1,
        ],
      ]);
      expect(res, 17.1);
    });

    test('list', () {
      final res = Evaluator().eval(['list', 1, true, 'text']);
      expect(res, [1, true, 'text']);
    });

    test('multi-level list', () {
      final res = Evaluator().eval([
        'list',
        1,
        true,
        ['list', 'text', 1.0],
      ]);
      expect(res, [
        1,
        true,
        ['text', 1.0]
      ]);
    });

    test('raw creator tests', () {
      final res = Evaluator().eval([
        "list",
        [
          "rawfirst",
          ["or", true, false],
          12
        ],
        [
          "rawlist",
          1,
          ["add", 1, 2],
          "&tata",
        ],
        [
          "rawobj",
          "a",
          12,
          "b",
          [
            "or",
            ["eq", 12, 13],
            ["less", 12, 13]
          ]
        ],
      ]);
      expect(res, [
        ["or", true, false],
        [
          1,
          ["add", 1, 2],
          "&tata"
        ],
        {
          "a": 12,
          "b": [
            "or",
            ["eq", 12, 13],
            ["less", 12, 13]
          ]
        }
      ]);
    });


    test('simple function test', () {
      final res = Evaluator().eval([
        'rawbegin',
        ['rawdefine', 'fibstep', [
          'rawbegin',
          ['define', 'c', ['add', '&a', '&b']],
          ['define', 'a', '&b'],
          ['define', 'b', '&c'],
          '&c',
        ]],
        ['rawdefine', 'a', 1],
        ['rawdefine', 'b', 1],
        '%fibstep', // 2
        '%fibstep', // 3
        '%fibstep', // 5
        '%fibstep', // 8
        '%fibstep', // 13
      ]);
      expect(res, 13);
    });

    // TODO: call from variable
    test('deep function test', (){
      final res = Evaluator().eval([
        'rawbegin',
        [
          [
            'rawevalup',
            'rawplus',
          ],
          1,
          2,
        ]
      ]);
      expect(3, res);
    });

    // TODO: custom functions
    // TODO: if-elseif-else
    // TODO: loops (forEach / for / while)
  });
}
