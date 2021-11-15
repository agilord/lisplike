import 'slib.dart';

class VarScope {
  Map<String, dynamic> vars;
  VarScope? parent;
  VarScope._(this.vars, this.parent);
  factory VarScope({Map<String, dynamic>? vars, VarScope? parent}) {
    vars ??= {if (parent != null) "#up": parent.vars};
    return VarScope._(vars, parent);
  }

  getvar(String varname) {
    if (vars.containsKey(varname)) {
      return vars[varname];
    }
    if (parent != null) {
      return parent!.getvar(varname);
    }
    // error
    return null;
  }

  wherevar(String varname) {
    return vars.containsKey(varname)
        ? 0
        : (parent == null ? -1 : 1 + parent!.wherevar(varname));
  }

  setvar(String varname, value) {
    return vars[varname] = value;
  }

  setrecvar(String varname, value) {
    final lvl = wherevar(varname);
    if (lvl < 0) {
      vars[varname] = varname;
    } else {
      VarScope ps = this;
      while (lvl >= 0) {
        ps = ps.parent!;
      }
      ps.vars[varname] = value;
    }
  }

  moveup(String varname, [int levels = 1]) {
    VarScope ps = this;
    while (ps.parent != null && !ps.vars.containsKey(varname)) {
      ps = ps.parent!;
    }
    final val = ps.vars[varname];
    while (levels >= 0 && ps.parent != null) {
      ps.vars.remove(varname);
      ps = ps.parent!;
    }
    return ps.vars[varname] = val;
  }
}

class Evaluator {
  Map<String, dynamic> state;
  Map<String, dynamic> vars;
  Evaluator._(this.state, this.vars);
  factory Evaluator([Map<String, dynamic>? state]) {
    state ??= {'vars': <String, dynamic>{}};
    return Evaluator._(state, state["vars"]);
  }

  _funceval(name, List pars) {
    if (name is String) {
      return bfuns[name]!(pars, this);
    }
    if (name is List) {
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
        if (val == name) {
          break; // fix point
        } else {
          name = val;
        }
      }

      // Base function call
      if (name is String) {
        for (int i = 0; i < pars.length; ++i) {
          pars[i] = eval(pars[i]);
        } // eval pars
        return _funceval(name, pars);
      }
      // lambda function call
      if (name is List && name[0] == 'lambda') {
        for (int i = 0; i < pars.length; ++i) {
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
          final vr = eval([":resolve", rest]);
          return vr;
        }
      case ':':
        return ["macrocall", rest];
    }
    return str;
  }
}
