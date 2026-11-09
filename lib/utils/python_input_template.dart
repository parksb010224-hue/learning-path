// 파일 역할: 문제 필터링과 Python 코드 입력 보조 기능: python input template
// 주요 선언부에는 담당 기능을 설명하는 한국어 주석을 추가했습니다.
import '../models/problem.dart';

/// Creates input-only code without embedding example values.
String buildPythonInputTemplate(Problem problem) {
  // Server-described input structures avoid inferring variable lengths from
  // a small public sample. No user-configured template is stored or read.
  const patterns = <String, String>{
    'two_ints': 'num1, num2 = map(int, input().split())\n',
    'one_int': 'num1 = int(input().strip())\n',
    'string': 's = input().strip()\n',
    'count_int_list': 'num1 = int(input().strip())\nvalues = list(map(int, input().split()))\n',
    'count_list_target': 'num1 = int(input().strip())\nvalues = list(map(int, input().split()))\ntarget = int(input().strip())\n',
    'count_words': 'num1 = int(input().strip())\nwords = input().split()\n',
    'graph_edges': 'num1, num2 = map(int, input().split())\nedges = [tuple(map(int, input().split())) for _ in range(num2)]\n',
    'coin_change': 'num1, target = map(int, input().split())\ncoins = list(map(int, input().split()))\n',
    'prefix_queries': 'num1, num2 = map(int, input().split())\nvalues = list(map(int, input().split()))\nqueries = [tuple(map(int, input().split())) for _ in range(num2)]\n',
    'binary_grid': 'num1, num2 = map(int, input().split())\ngrid = [input().strip() for _ in range(num1)]\n',
    'pair_rows': 'num1 = int(input().strip())\npairs = [tuple(map(int, input().split())) for _ in range(num1)]\n',
    'command_rows': 'num1 = int(input().strip())\ncommands = [input().split() for _ in range(num1)]\n',
  };
  final specified = patterns[problem.inputPattern];
  if (specified != null) return specified;
  final samples = problem.examples
      .map((e) => e.inputData.replaceAll('\r\n', '\n').trimRight())
      .where((s) => s.isNotEmpty)
      .map((s) => s.split('\n')).toList();
  if (samples.isEmpty) return '# 입력 설명에 맞게 입력을 받아주세요.\n';
  final lines = samples.first;
  final code = <String>[];
  var numbers = 0;
  var strings = 0;
  /// tokens: 이 기능의 화면 상태·요청·데이터 처리를 담당합니다.
  List<String> tokens(String s) => s.trim().split(RegExp(r'\s+'));
  /// integer: 이 기능의 화면 상태·요청·데이터 처리를 담당합니다.
  bool integer(String s) => RegExp(r'^[+-]?\d+$').hasMatch(s);
  /// numeric: 이 기능의 화면 상태·요청·데이터 처리를 담당합니다.
  bool numeric(String s) => double.tryParse(s) != null;
  /// name: 이 기능의 화면 상태·요청·데이터 처리를 담당합니다.
  String name(bool number) => number ? 'num${++numbers}' : 's${++strings}';
  /// reader: 이 기능의 화면 상태·요청·데이터 처리를 담당합니다.
  String reader(List<String> rows) {
    final allInt = rows.every((r) => tokens(r).every(integer));
    final allNum = rows.every((r) => tokens(r).every(numeric));
    final scalar = rows.every((r) => tokens(r).length == 1);
    if (!allNum) return scalar ? 'input().strip()' : 'input().split()';
    final type = allInt ? 'int' : 'float';
    return scalar ? '$type(input().strip())' : 'list(map($type, input().split()))';
  }

  // Read repeated rows using the actual count, not the sample's count.
  final counted = lines.length > 1 && samples.every((sample) =>
      int.tryParse(sample.first.trim()) == sample.length - 1);
  if (counted) {
    final expression = reader(samples.expand((s) => s.skip(1)).toList());
    return 'num1 = int(input().strip())\n'
        'values = [$expression for _ in range(num1)]\n';
  }
  for (var i = 0; i < lines.length; i++) {
    final row = tokens(lines[i]);
    if (row.length == 1) {
      final variable = numeric(row.first) ? name(true)
          : (++strings == 1 ? 's' : 's$strings');
      code.add('$variable = ${reader([lines[i]])}');
      continue;
    }
    final array = (i > 0 && int.tryParse(lines[i - 1].trim()) == row.length) ||
        row.length > 5 || samples.any((s) =>
            s.length <= i || tokens(s[i]).length != row.length);
    final allNum = row.every(numeric);
    final type = row.every(integer) ? 'int' : 'float';
    if (array) {
      code.add(allNum ? 'values${i + 1} = list(map($type, input().split()))'
          : 'strings${i + 1} = input().split()');
    } else if (allNum || row.every((s) => !numeric(s))) {
      final names = List.generate(row.length, (_) => name(allNum)).join(', ');
      code.add(allNum ? '$names = map($type, input().split())'
          : '$names = input().split()');
    } else {
      code.add('parts${i + 1} = input().split()');
      for (var j = 0; j < row.length; j++) {
        final value = 'parts${i + 1}[$j]';
        final conversion = integer(row[j]) ? 'int' : 'float';
        code.add('${name(numeric(row[j]))} = ${numeric(row[j]) ? '$conversion($value)' : value}');
      }
    }
  }
  return '${code.join('\n')}\n';
}
