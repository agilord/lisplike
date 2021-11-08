import 'dart:convert';

import 'slib.dart';

class Evaluator {
  Map<String, dynamic> state;
  Map<String, dynamic> vars;
  Evaluator._(this.state, this.vars);
  factory Evaluator([Map<String, dynamic>? state]) {
    state ??= {'vars': <String, dynamic>{}};
    return Evaluator._(state, state["vars"]);
  }

  _funceval(name, List pars) {
    if(name is String) {
      return bfuns[name]!(pars, this);
    }
    if(name is List) {
      vars = {"#up": vars};
      final parnames = name[1];
      final body = name[2];
      for (var i = 0; i < parnames.length; ++i) {
        vars[parnames[i]] = pars[i];
      }
      final ret = eval(body);
      vars = vars["#up"];
      return ret;
    }
  }

  // evaluates "elem" in 'eval' context.
  eval(elem) {
    if (elem is List) {
      var name = elem.first;
      var pars = List.from(elem.sublist(1));
      // name resolution
      while (name is String) {
        final val = parseStr(name);
        if (val == name)
          break; // fix point
        else
          name = val;
      }

      // Base function call
      if (name is String) {
        for(int i = 0; i < pars.length; ++i) {
          pars[i] = eval(pars[i]);
        } // eval pars
        return _funceval(name, pars);
      }
      // lambda function call
      if (name is List && name[0] == 'lambda') {
        for(int i = 0; i < pars.length; ++i) {
          pars[i] = eval(pars[i]);
        } // eval pars
        return _funceval(name, pars);
      }
      // macrocall
      if (name is List && name[0] == 'macrocall') {
        return _funceval(name[1], pars); // no param eval
      }
    }
    if (elem is String) {
      return parseStr(elem);
    }
    if (elem is num) {
      //print(elem.runtimeType); // can be int or double if converted from JSON
      return elem.toDouble();
    }
    if (elem is Map) {
      return elem;
    }
    if (elem is bool || elem == null) {
      return elem;
    }
  }

  parseStr(String str) {
    final first = str[0];
    final rest = str.substring(1);
    switch (first) {
      case '\'':
        return rest;
      case '&':
        {
          final vr = this.eval([":resolve", rest]);
          return vr;
        }/*
      case '%':
        {
          final vr = this.eval([":resolv", rest]);
          return this.eval(vr);
        }*/
      case ':':
        return ["macrocall", rest];
    }
    return str;
  }
}
