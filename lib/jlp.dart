import 'slib.dart';

abstract class Scope {
  String get name;
  Scope? parent;
  Scope(this.parent);
  hasVar(String name) => false;
  getVar(String name) => ArgumentError("get $name at wrong place");
  setVar(String name, value) => parent!.setVar(name, value);

  resolv(String name) {
    if (hasVar(name)) {
      return getVar(name);
    } else {
      return parent!.resolv(name);
    }
  }

  moveUpValue(String name, value, [int level = 1]) {
    if (hasVar(name)) {
      setVar(name, value);
      level -= 1;
    }
    if (level > 0) {
      parent!.moveUpValue(name, value);
    }
  }

  moveUp(String name, [int level = 1]) {
    if (hasVar(name)) {
      final value = getVar(name);
      moveUpValue(name, value, level);
    }
  }
}

// May contain native functions, i.e. `add`, `mul`
class NativeScope extends Scope {
  @override
  String get name => 'nativescpe';
  NativeScope(Scope? parent) : super(parent);

  // TODO: native functions
}

// Just in-language variables
class VarScope extends Scope {
  @override
  String get name => 'varscope';
  Map<String, dynamic> vars;
  VarScope._(this.vars, Scope? parent) : super(parent);
  factory VarScope(Scope? parent, [Map<String, dynamic>? vars]) {
    vars ??= {if (parent != null) "#up": parent};
    return VarScope._(vars, parent);
  }

  @override
  hasVar(String varname) {
    return vars.containsKey(varname);
  }

  @override
  getVar(String name) {
    return vars[name];
  }

  @override
  setVar(String name, value) {
    return vars[name] = value;
  }
}

abstract class Evaler extends Scope {
  Evaler(Scope? parent) : super(parent);
  eval();
}

// For ex. storing results, etc.
class ValueEval extends Evaler {
  @override
  String get name => 'valueeval';
  dynamic value;
  ValueEval(this.value, Scope? parent) : super(parent);

  @override
  eval() {
    if (value is List) {
      var name = value.first;
      var pars = List.from(value.sublist(1));

      // name resolution
      if (name is String) {
        name = StringEval(name, this);
      }

      return FuncEval(name, pars, this);
    }

    if (value is String) {
      return StringEval(value, this);
    }

    if (value is num) {
      // can be int or double
      return value.toDouble();
    }

    return value;
  }
}

class FuncEval extends Evaler {
  @override
  String get name => 'funceval';
  FuncEval(this.func, this.pars, Scope? parent) : super(parent);
  dynamic func;
  dynamic pars;
  @override
  eval() {
    while (func is Evaler) {
      func = func.eval();
    }

    if (func is List && func[0] == 'macrocall') {
      func = ValueEval(func[1], this);
      while (func is Evaler) {
        func = func.eval();
      }
    } else {
      pars = BlockEval(pars, this);
    }
    while (pars is Evaler) {
      pars = pars.eval();
    }

    if (func is Function) {
      // native call
      return func(pars, this);
    } else if (func[0] == 'lambda') {
      // lambda call
      final vars = VarScope(this);
      for (var i = 0; i < pars.lenght && i < func[1].length; i++) {
        vars.setVar(func[1][i], pars[i]);
      }
      return ValueEval(func[2], vars);
    }
  }
}

class StringEval extends Evaler {
  @override
  String get name => 'stringeval';
  String str;
  StringEval(this.str, Scope? parent) : super(parent);
  // TODO extract parseStr
  @override
  eval() {
    final first = str[0];
    final rest = str.substring(1);
    switch (first) {
      case '\'':
        return rest.endsWith('\'') ? rest.substring(0, rest.length - 1) : rest;
      case '&':
        {
          final vr = resolv(rest);
          return vr;
        }
      case ':':
        return ["macrocall", rest];
    }
    return str;
  }
}

class BlockEval extends Evaler {
  @override
  String get name => 'blockeval';
  List<dynamic> elems = [];
  BlockEval.empty(Scope? parent) : super(parent);
  factory BlockEval(List<dynamic> vals, Scope? parent) {
    final block = BlockEval.empty(parent);
    block.elems = vals.map((e) => ValueEval(e, block)).toList();
    return block;
  }
  @override
  eval() {
    for (var i = 0; i < elems.length; ++i) {
      while (elems[i] is Evaler) {
        elems[i] = elems[i].eval();
      }
    }
    return elems;
  }
}

class Evaluator {
  VarScope root;
  Evaluator._(this.root);
  factory Evaluator([VarScope? root]) {
    root ??= VarScope(null);
    return Evaluator._(root);
  }
  // evaluates "elem" in 'eval' context.
  eval(elem) {
    var val = ValueEval(elem, root);
    while (val is Evaler) {
      val = val.eval();
    }
  }
}
