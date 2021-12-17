import 'dart:ffi';

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
  final funs;
  NativeScope(this.funs, [Scope? parent]) : super(parent);

  @override
  hasVar(String name) {
    return funs.containsKey(name);
  }
  @override
  getVar(String name) {
    return funs[name];
  }
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

class EvPos {
  Evaler ev;
  dynamic pos;
  EvPos(this.ev, this.pos);
}

// For ex. storing results, etc.
class ValueEval extends Evaler {
  @override
  String get name => 'valueeval';
  dynamic value;
  ValueEval(this.value, Scope? parent) : super(parent);

  @override
  hasVar(String name) =>
    name == value;

  getVar(String name) =>
     (name == 'value') ? value : null;

  setVar(String name, value) =>
     (name == 'value') ? this.value = value :
      parent!.setVar(name, value);


  @override
  eval() {
    if (value is List) {
      var name = value.first;
      var pars = List.from(value.sublist(1));

      // name resolution
      if (name is String) {
        name = StringEval(name, this);
      }

      return ListEval(name, pars, this);
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

class ListEval extends Evaler {
  @override
  String get name => 'listeval';
  ListEval(this.head, this.tail, Scope? parent) : super(parent);
  dynamic head;
  dynamic tail;
  @override
  hasVar(String name) => {'head', 'tail'}.contains(name);
  getVar(String name) {
    if (name == 'head') return head;
    if (name == 'tail') return tail;
  }

  setVar(String name, value) {
    if (name == 'head') return head = value;
    if (name == 'tail') return tail = value;
    return parent!.setVar(name, value);
  }

  @override
  eval([pos]) {
    if (head is Evaler) {
      return EvPos(head, 'head');
    }

    if (head is List && head[0] == 'macrocall') {
      final newHead = ValueEval(head[1], this);
      return MacroEval(newHead, tail, parent);
    } else {
      final newPars = BlockEval(tail, this);
      return FuncEval(head, newPars, parent);
    }
  }
}

class FuncEval extends Evaler {
  String get name => 'funceval';
  dynamic func;
  dynamic pars;
  FuncEval(this.func, this.pars, Scope? parent) : super(parent);

  hasVar(name) => {'func', 'pars'}.contains(name);
  getVar(name) => name == 'func'
      ? this.func
      : name == 'pars'
          ? this.pars
          : null;
  setVar(name, value) => name == 'func'
      ? this.func = value
      : name == 'pars'
          ? this.pars = value
          : parent!.setVar(name, value);

  eval() {
    if (func is Evaler) return EvPos(func, 'func');
    if (pars is Evaler) return EvPos(pars, 'pars');

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

class MacroEval extends Evaler {
  String get name => 'maccroeval';
  dynamic func;
  dynamic pars;
  MacroEval(this.func, this.pars, Scope? parent) : super(parent);
  hasVar(name) => {'func', 'pars'}.contains(name);
  getVar(name) => name == 'func'
      ? this.func
      : name == 'pars'
          ? this.pars
          : null;
  setVar(name, value) => name == 'func'
      ? this.func = value
      : name == 'pars'
          ? this.pars = value
          : parent!.setVar(name, value);
  eval() {
    if (func is Evaler) return [func, 'func'];
    return FuncEval(func, pars, parent);
  }
}

class StringEval extends Evaler {
  @override
  String get name => 'stringeval';
  String str;
  StringEval(this.str, Scope? parent) : super(parent);

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
        return ValueEval(["macrocall", rest], parent);
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
  hasVar(String name) => name == 'elems';
  getVar(String name) => name == 'elems' ? elems : null;
  setVar(String name, value) => name == 'elems' ? elems = value : parent!.setVar(name, value);
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
  Scope root;
  List<EvPos> tape;
  Evaluator._(this.root, this.tape);
  factory Evaluator({Scope? root, List<EvPos>? tape}) {
    root ??= NativeScope(bfuns, VarScope(null));

    tape ??= [];
    return Evaluator._(root, tape);
  }

  eval([curr]) {
    if (curr is Evaler) {
      // Start tape with curr
      tape.add(EvPos(curr, null));
    } else if (curr != null) {
      curr = ValueEval(curr, root);
      tape.add(EvPos(curr, null));
    }

    while (tape.isNotEmpty) {
      final ret = tape.last.ev.eval();
      if (ret is EvPos) {
        // Add computablevalue to tape
        tape.add(ret);
      } else if (tape.last.pos != null) {
        // Rewrite previous value on the tape
        final backwritePos = tape.last.pos;
        tape.removeLast();
        tape.last.ev.setVar(backwritePos, ret);
      } else {
        // Stop execution
        return ret;
      }
    }
  }
}
