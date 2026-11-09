// 파일 역할: Flutter 단위·위젯 테스트: python input template test
// 주요 선언부에는 담당 기능을 설명하는 한국어 주석을 추가했습니다.
import 'package:flutter_test/flutter_test.dart';
import '../lib/models/problem.dart';
import '../lib/utils/python_input_template.dart';

/// problem: 이 기능의 화면 상태·요청·데이터 처리를 담당합니다.
Problem problem(String input) => Problem(
  id: 1, title: '', difficulty: '', category: '', description: '',
  examples: [ProblemExample(inputData: input, expectedOutput: '')],
  isSolved: false,
);

/// main: 이 기능의 화면 상태·요청·데이터 처리를 담당합니다.
void main() {
  test('two integers', () {
    expect(buildPythonInputTemplate(problem('5 3')),
        'num1, num2 = map(int, input().split())\n');
  });
  test('single string', () {
    expect(buildPythonInputTemplate(problem('abcde')), 's = input().strip()\n');
  });
  test('count and string array', () {
    expect(buildPythonInputTemplate(problem('5\napp baa cdd eee rdd')),
        'num1 = int(input().strip())\nstrings2 = input().split()\n');
  });
  test('count and repeated rows', () {
    expect(buildPythonInputTemplate(problem('3\napp\nbaa\ncdd')),
        'num1 = int(input().strip())\nvalues = [input().strip() for _ in range(num1)]\n');
  });
  test('integer array', () {
    expect(buildPythonInputTemplate(problem('3\n1 2 3')),
        'num1 = int(input().strip())\nvalues2 = list(map(int, input().split()))\n');
  });
}
