import 'dart:convert';

import 'slib.dart';

abstract class Func {
  Future call(Stream data, List stack, Map args);
}

class Adder extends Func {
  @override
  call(data, stack, args) async {
    final rhs = args["rhs"];
    final lhs = args["lhs"];
  }
}

class Evaluator {
  Map<String, dynamic> state;
  Evaluator._(this.state);
  factory Evaluator([Map<String, dynamic>? state]) {
    return Evaluator._(Map<String, dynamic>.from(state ??
        {
          'var': {},
          'hand': {},
          'call': [],
          'top': null,
        }));
  }

  eval(elem) {
    if (elem is List) {
      final name = elem.first;
      final pars = elem.sublist(1);
      return rcall(name, pars, this);
    }
    if (elem is String) {
      return parseSpec(elem);
    }
    if (elem is num) {
      //print(elem.runtimeType); // can be int or double
      return elem.toDouble();
    }
    if (elem is Map) {
      return elem;
    }
    if (elem is bool || elem == null) {
      return elem;
    }
  }

  funcall(name, List pars) {
    if (true /* not macro */) {
      pars = pars.map((e) => eval(e)).toList();
    }
    if (name == 'add') {
      return pars[0] + pars[1];
    }
    if (name == 'list') {
      return pars;
    }
  }

  parseSpec(String str) {
    if (str.startsWith('\'') && str.endsWith('\'')) {
      return str.substring(1, str.length - 1);
    }
    final first = str[0];
    final rest = str.substring(1);
    switch (first) {
      case '\$':
        return state['vars'][rest];
    }
    return str;
  }
}

parseProg(String prog) {
  final lines = prog.split('\x00'); // temporary, should split by lines
  final progObjs = lines.map(json.decode).toList();
  final ev = Evaluator();
  return progObjs.map((prog) => ev.eval(prog));
}
