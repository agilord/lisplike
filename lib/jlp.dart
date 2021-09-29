import 'dart:convert';

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
  Stream data = Stream.empty();
  dynamic prog;
  List scratch;
  Evaluator._(this.prog, this.scratch);
  factory Evaluator(prog, [List? scratch]) {
    return Evaluator._(prog, scratch ?? []);
  }

  run([Stream? data]) {
    if (data != null) this.data = data;
    return eval(prog);
    scratch = [];
    for (final stm in prog) {
      scratch.add(eval(stm));
    }
    return scratch;
  }

  eval(elem) {
    if (elem is String) {
      //yield* parseSpec(elem);
      return elem;
    }
    if (elem is num) {
      //print(elem.runtimeType); // can be int or double
      return elem;
    }
    if (elem is bool) {
      return elem;
    }
    if (elem == null) {
      return elem;
    }
    if (elem is Map) {
      return elem;
    }
    if (elem is List) {
      final name = elem.first;
      final pars = elem.sublist(1);
      return funcall(name, pars);
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

  parseSpec(String string) sync* {
    if (string.isEmpty) {
      yield "";
      return;
    }
    final first = string[0];
    final rest = string.substring(1);
    switch (string[0]) {
      case '\'':
        yield rest;
        return;
      case '#':
        yield scratch[int.parse(rest)];
        return;
      case '~':
      default:
        return;
    }
  }
}

Evaluator parseProg(String prog) {
  final lines = prog.split('\x00'); // temporary, should split by lines
  final progObjs = lines.map(json.decode).toList();
  return Evaluator(progObjs);
}
