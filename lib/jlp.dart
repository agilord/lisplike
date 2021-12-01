import 'slib.dart';

abstract class Scope {
  String get name;
  Scope? parent;
  Scope();
  Scope._(this.parent);
  hasVar(String name) => false;
  getVar(String name) => ArgumentError("get $name at wrong place");
  setVar(String name, value) => parent!.setVar(name, value);

  resolv(String name) {
    if(this.hasVar(name)) return getVar(name);
    else return parent!.resolv(name);
  }
  moveUpValue(String name, value, [int level = 1]) {
    if(this.hasVar(name)) {
      this.setVar(name, value);
      level -= 1;
    }
    if(level > 0) {
      parent!.moveUpValue(name, value);
    }
  }
  moveUp(String name, [int level = 1]) {
    if(this.hasVar(name)) {
      final value = this.getVar(name);
      moveUpValue(name, value, level);
    }
  }
}

// May contain native functions, i.e. `add`, `mul`
class NativeScope extends Scope {
  @override
  String get name => 'nativescpe';

  // TODO: native functions
}

// Just in-language variables
class VarScope extends Scope {
  @override
  String get name => 'varscope';
  Map<String, dynamic> vars;
  VarScope._(this.vars, Scope? parent) : super._(parent);
  factory VarScope({Map<String, dynamic>? vars, Scope? parent}) {
    vars ??= {if (parent != null) "#up": parent};
    return VarScope._(vars, parent);
  }

  @override hasVar(String varname) {
    return vars.containsKey(varname);
  }
  @override getVar(String name) {
    return vars[name];
  }
  @override setVar(String name, value) {
    return vars[name] = value;
  }
}

abstract class Evaler extends Scope {
  eval();
}

// For ex. storing results, etc.
class ValueEval extends Evaler {
  @override
  String get name => 'valueeval';
  dynamic value;
  ValueEval(this.value);
  eval() => eval_from_Evaluator(value);
}

class FuncEval extends Evaler {
  @override
  String get name => 'funceval';
  FuncEval(this.func, this.pars);
  dynamic func;
  dynamic pars;
  // TODO extract _funceval
  eval() {

  }
}

class StringEval extends Evaler {
  @override String get name => 'stringeval';
  String str;
  StringEval(this.str)
  // TODO extract parseStr
  @override eval() {

  }
}

class BlockEval extends Evaler {
  @override
  String get name => 'blockeval';
  List<dynamic> elems;
  BlockEval(this.elems);
  factory BlockEval.evalAll(List<dynamic> vals) {
    return BlockEval(vals.map((e) => ValueEval(e)).toList()); 
  }
  eval() {
    for(var i = 0; i < elems.length; ++i) {
      while(elems[i] is Evaler) {
        elems[i] = elems[i].eval();
      }
    }
    return elems;
  }
}

class Evaluator {
  VarScope root;
  VarScope scope;
  Evaluator._(this.root, this.scope);
  factory Evaluator([VarScope? root]) {
    root ??= VarScope();
    return Evaluator._(root, root);
  }

  _funceval(name, List pars) {
    if (name is String) {
      return bfuns[name]!(pars, this);
    }
    if (name is List) {
      scope = VarScope(parent: scope);
      final parnames = name[1];
      final body = name[2];
      for (var i = 0; i < parnames.length; ++i) {
        scope.setvar(parnames[i], pars[i]);
      }
      final ret = eval(body);
      scope = scope.parent!;
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
