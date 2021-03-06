// ["add", x, y] -> dart: add(x, y)

import 'package:jlp/jlp.dart';

typedef Fun = dynamic Function(List pars, Evaluator ctx);

final bfuns = <String, Fun>{
  // Memory handling
  'define': (pars, ctx) {
    assert(pars[0] is String, 'rawdefine: not string key');
    ctx.scope.setvar(pars[0], pars[1]);
    return '&${pars[0]}';
  },
  'resolve': (pars, ctx) {
    return ctx.scope.getvar(pars[0]);
  },
  'new_scope': (pars, ctx) {
    final vars = pars.length >= 1 ? pars[0] : {};
    ctx.scope = VarScope(parent: ctx.scope, vars: vars);
    return null;
  },
  'del_scope': (pars, ctx) {
    ctx.scope = ctx.scope.parent!;
    return null;
  },
  'up': (pars, ctx) {
    final name = pars[0];
    final times = pars.length >= 2 ? pars[1] : 1;
    ctx.scope.moveup(name, times);
    return null;
  },

  // Execution control
  'do': (pars, ctx) {
    return pars.last;
  },
  'if': (pars, ctx) {
    final cond = pars[0];
    final succ = pars[1];
    final fail = pars.length >= 3 ? pars[2] : null;
    if (ctx.eval(cond)) {
      return ctx.eval(succ);
    } else {
      return ctx.eval(fail);
    }
  },
  'while': (pars, ctx) {
    final cond = pars[0];
    final body = pars[1];
    dynamic data;
    while (ctx.eval(cond)) {
      data = ctx.eval(body);
    }
    return data;
  },

  // Element creators
  'pass': (pars, ctx) => pars[0],
  'list': (pars, ctx) => pars,
  'obj': (pars, ctx) {
    // pars: [key_1, val_1, key_2, val_2, ...]
    assert(pars.length % 2 == 0, 'rawobj: not paired');
    final ret = <String, dynamic>{};
    for (var i = 0; i < pars.length; i += 2) {
      assert(pars[i] is String, 'rawobj: not string key');
      ret[pars[i]] = pars[i + 1];
    }
    return Map<String, dynamic>.unmodifiable(ret);
  },

  // Operator calls
  'add': (pars, ctx) => pars[0] + pars[1],
  'sub': (pars, ctx) => pars[0] - pars[1],
  'mul': (pars, ctx) => pars[0] * pars[1],
  'div': (pars, ctx) => pars[0] / pars[1],
  'mod': (pars, ctx) => pars[0] % pars[1],
  'eq': (pars, ctx) => pars[0] == pars[1],
  'less': (pars, ctx) => pars[0] < pars[1],
  'greater': (pars, ctx) => pars[0] > pars[1],
  'not': (pars, ctx) => !pars[0],
  'or': (pars, ctx) => pars[0] | pars[1],
  'and': (pars, ctx) => pars[0] & pars[1],
  'ind': (pars, ctx) => pars[0][pars[1]],
};
