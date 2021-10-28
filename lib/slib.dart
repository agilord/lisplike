// ["add", x, y] -> dart: add(x, y)

import 'dart:io';

import 'package:jlp/jlp.dart';

typedef Fun = dynamic Function(List pars, Evaluator ctx);

final rfuns = <String, Fun>{
  // raw element constructors
  'rawfirst': (pars, ctx) => pars[0],
  'rawlist': (pars, ctx) => pars,
  'rawobj': (pars, ctx) {
    // pars: [key_1, val_1, key_2, val_2, ...]
    assert(pars.length % 2 == 0, 'rawobj: not paired');
    final ret = <String, dynamic>{};
    for (var i = 0; i < pars.length; i += 2) {
      assert(pars[i] is String, 'rawobj: not string key');
      ret[pars[i]] = pars[i + 1];
    }
    return Map<String, dynamic>.unmodifiable(ret);
  },

  'rawplus': (pars, ctx) => pars[0] + pars[1],
  'rawlength': (pars, ctx) => pars[0].length,

  // variable declaration
  'rawdefine': (pars, ctx) {
    assert(pars[0] is String, 'rawdefine: not string key');
    ctx.state["var"][pars[0]] = pars[1];
    return '&${pars[0]}';
  },
  // variable resolution
  'rawresolv': (pars, ctx) {
    var now = ctx.state["var"];
    while (now is Map) {
      if (now.containsKey(pars[0])) {
        return now[pars[0]];
      }
      now = now["#up"];
    }
    assert(false, 'rawresolv: not found, ${ctx.state}'); // or maybe just null?
    return null;
  },
  // Move a variable one var-context upward.
  'rawup': (pars, ctx) {
    var now = ctx.state["var"];
    while (now is Map) {
      if (now.containsKey(pars[0])) {
        if (now["#up"] is Map) {
          now["#up"][pars[0]] = now[pars[0]];
          now.remove(pars[0]);
          return true;
        } else {
          // variable is at the top ctx
          return false;
        }
      }
      now = now["#up"];
    }
    assert(false, 'rawup: not found');
    return null;
  },

  // return first_par[second_par]
  'rawindex': (pars, ctx) {
    if (pars[1] is num) {
      return pars[0][pars[1]];
    }
    if (pars[1] is String) {
      return pars[0][pars[1]];
    }
    assert(false, 'rawindex: wrong index type');
    return null;
  },

  // Evals every element, and returns the last.
  'rawbegin': (pars, ctx) {
    var data;
    for (final p in pars) {
      data = ctx.eval(p);
    }
    return data;
  },
  // Evals all element, returns a list of values.
  'rawall': (pars, ctx) => [for (final p in pars) ctx.eval(p)],
  // pars[0] is name, pars[1...] is real params, evals real params, calls name
  'raweval': (pars, ctx) {
    final name = pars[0];
    final rest = pars.sublist(1);
    return ctx.eval([name, for (final p in rest) ctx.eval(p)]);
  },
  'rawevalup': (pars, ctx) {
    final name = pars[0];
    final realpars = ctx.state["parslist"].last;
    return ctx.eval([name, for (final p in realpars) ctx.eval(p)]);
  },

  'readvar': (pars, ctx) => ctx.state["var"],
  'readparslist': (pars, ctx) => ctx.state["parslist"],
};

// raw calls don't eval their arguments
rcall(name, pars, Evaluator ev) {
  if (name is String) {
    if (rfuns.containsKey(name)) {
      // raw call
      return rfuns[name]!(pars, ev);
    }
  }
  if (name is List) {
    // Function call
    ev.state["funlist"].add(name);
    ev.state["parslist"].add(pars);
    final ret = ev.eval(name);
    ev.state["funlist"].removeLast();
    ev.state["parslist"].removeLast();
    return ret;
  }
  // else eval call
  return evcall(name, pars, ev);
}

final efuns = <String, Fun>{
  // handle variable scopes/frames
  'newframe': (pars, ev) {
    ev.state["var"] = {"#up": ev.state["var"]};
    return null;
  },
  'delframe': (pars, ev) {
    ev.state["var"] = ev.state["var"]["#up"];
    return null;
  },

  // Complex object creators
  'pass': (pars, ev) => pars[0],
  'list': (pars, ev) => pars,
  'obj': (pars, ev) {
    assert(pars.length % 2 == 0);
    final ret = <String, dynamic>{};
    for (var i = 0; i < pars.length; i += 2) {
      assert(pars[i] is String, 'obj: not string key');
      ret[pars[i]] = pars[i + 1];
    }
    return ret;
  },

  // var creation
  'define': (pars, ev)
  {
    ev.state['var'][pars[0]] = pars[1];
    return '&${pars[0]}';
  },

  'add': (pars, ev) => pars.reduce((a, b) => a+b),
  'less': (pars, ev) => pars[0] < pars[1],
  'eq': (pars, ev) => pars[0] == pars[1],
  'not': (pars, ev) => !pars[0],
  'or': (pars, ev) => pars[0] | pars[1],
};

// parameters are evaluated before interpretation
evcall(name, pars, Evaluator ev) {
  assert(pars is List);
  pars = (pars as List).map((e) {
    return ev.eval(e);
  }).toList();
  name = ev.eval(name);

  if(efuns.keys.contains(name)) {
    return efuns[name]!(pars, ev);
  }
}
