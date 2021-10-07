// ["add", x, y] -> dart: add(x, y)

import 'dart:io';

import 'package:jlp/jlp.dart';

// raw calls don't eval their arguments
rcall(name, pars, Evaluator ev) {
  final firstpar = pars[0];
  switch (name) {
    // just raw element constructors
    case 'rawpass':
      return firstpar;
    case 'rawlist':
      return pars;
    case 'rawobj':
      {
        assert(pars.length % 2 == 0, 'rawobj: not paired');
        final ret = <String, dynamic>{};
        for (var i = 0; i < pars.length; i += 2) {
          assert(pars[i] is String, 'rawobj: not string key');
          ret[pars[i]] = pars[i + 1];
        }
        return Map<String, dynamic>.unmodifiable(ret);
      }

    // variable declaration/resoution
    case 'rawdefine':
      {
        assert(pars[0] is String, 'rawdefine: not string key');
        ev.state[pars[0]] = pars[1];
        return '&${pars[0]}';
      }
    case 'rawresolv':
      {
        var now = ev.state["var"];
        while (now is Map) {
          if (now.containsKey(firstpar)) {
            return now[firstpar];
          }
          now = now["&up"];
        }
        assert(false, 'rawresolv: not found'); // or maybe just null?
        return null;
      }
    case 'rawup':
      {
        var now = ev.state["var"];
        while (now is Map) {
          if (now.containsKey(firstpar)) {
            if (now["&up"] is Map) {
              now["&up"][firstpar] = now[firstpar];
              now.remove(firstpar);
              return true;
            } else {
              // variable is at the top level
              return false;
            }
          }
          now = now["&up"];
        }
        assert(false, 'rawup: not found');
        return null;
      }
  }
  return evcall(name, pars, ev);
}

// parameters are evaluated before interpretation
evcall(name, pars, Evaluator ev) {
  assert(pars is List);
  pars = (pars as List).map((e) {
    return ev.eval(e);
  }).toList();
  name = ev.eval(name);

  switch (name) {
    // eval parameters as a function
    case 'eval':
      return ev.eval(pars);

    // variable context-frames
    case 'newframe':
      ev.state["var"] = {"&up": ev.state["var"]};
      return null;
    case 'delframe':
      ev.state["var"] = ev.state["&up"];
      return null;

      // evaled element creators
    case 'pass':
      return pars[0];
    case 'list':
      return pars;
    case 'obj':
      {
        assert(pars.length % 2 == 0);
        final ret = <String, dynamic>{};
        for (var i = 0; i < pars.length; i += 2) {
          assert(pars[i] is String, 'obj: not string key');
          ret[pars[i]] = pars[i + 1];
        }
        return ret;
      }

      // some math function
    case 'add':
      return pars.reduce((a, b) => a + b);
    case 'less':
      return pars[0] < pars[1];
    case 'eq':
      return pars[0] == pars[1];
    case 'not':
      return !pars[0];
    case 'or':
      return pars[0] | pars[1];
  }
}
