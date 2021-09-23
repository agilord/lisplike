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
  List prog;
  List scratch;
  Evaluator._(this.prog, this.scratch);
  factory Evaluator(List prog, [List? scratch]) {
    return Evaluator._(prog, scratch ?? []);
  }

  Iterable run([Stream? data]) sync* {
    if(data != null) this.data = data;
    scratch = [];
    for(final stm in prog) {
      scratch.addAll(eval(stm));
    }
    yield* scratch;
  }

  Iterable eval(elem) sync*{
    if(elem is String) {
      yield* parseSpec(elem);
    }
    if(elem is num) {
      print(elem.runtimeType);
      yield elem;
    }
    if(elem is bool) {
      yield elem;
    }
    if(elem == null) {
      return;
    }
    if(elem is List) {
      // Code block
      final neva = Evaluator(elem);
      yield* neva.run(data);
    }
    if(elem is Map) {
      final name = elem["call"];
      final pars = elem["pars"];
      yield* funcall(name, pars);
    }
  }

  funcall(name, pars) sync* {
    if(name == 'pars') yield pars;
    if(name == 'add') yield eval(pars['rhs']).first + eval(pars['lhs']).first;
    if(name == 'pop') {
      scratch.removeLast();
      return;
    }
  }

  parseSpec(String string) sync* {
    if(string.isEmpty) {
      yield "";
      return;
    }
    final first = string[0];
    final rest = string.substring(1);
    switch(string[0]) {
      case '\'':
        yield rest;
        return;
      case '#':
        yield scratch[int.parse(rest)];
        return;
      case '~':
      default: return;
    }
  }
}

Evaluator parseProg(String prog) {
  final lines = prog.split('\x00'); // temporary, should split by lines
  final progObjs = lines.map(json.decode).toList();
  return Evaluator(progObjs);
}
