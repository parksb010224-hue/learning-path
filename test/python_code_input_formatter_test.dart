// 파일 역할: Flutter 단위·위젯 테스트: python code input formatter test
// 주요 선언부에는 담당 기능을 설명하는 한국어 주석을 추가했습니다.
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import '../lib/utils/python_code_input_formatter.dart';

/// value: 이 기능의 화면 상태·요청·데이터 처리를 담당합니다.
TextEditingValue value(String text, [int? cursor]) => TextEditingValue(
  text: text,
  selection: TextSelection.collapsed(offset: cursor ?? text.length),
);

/// main: 이 기능의 화면 상태·요청·데이터 처리를 담당합니다.
void main() {
  const formatter = PythonCodeInputFormatter();
  /// type: 이 기능의 화면 상태·요청·데이터 처리를 담당합니다.
  TextEditingValue type(TextEditingValue old, String character) {
    final cursor = old.selection.extentOffset;
    return formatter.formatEditUpdate(old, value(
      old.text.replaceRange(cursor, cursor, character),
      cursor + character.length,
    ));
  }

  test('Enter adds four spaces after a colon', () {
    final result = type(value('if a == b:'), '\n');
    expect(result.text, 'if a == b:\n    ');
    expect(result.selection.extentOffset, result.text.length);
  });

  test('four backspaces remove indentation and allow else', () {
    var current = type(value('if a == b:\n    print(aaaa)'), '\n');
    expect(current.text, 'if a == b:\n    print(aaaa)\n    ');
    for (var i = 0; i < 4; i++) {
      final deletion = value(current.text.substring(0, current.text.length - 1));
      current = formatter.formatEditUpdate(current, deletion);
      expect(current, deletion);
    }
    expect(current.text, 'if a == b:\n    print(aaaa)\n');
    for (final character in 'else:'.split('')) {
      current = type(current, character);
    }
    current = type(current, '\n');
    expect(current.text, 'if a == b:\n    print(aaaa)\nelse:\n    ');
  });

  test('Enter retains nested indentation', () {
    expect(type(value('    if a == b:'), '\n').text,
        '    if a == b:\n        ');
  });

  for (final pair in {'(': ')', '{': '}', '[': ']'}.entries) {
    test('pairs ${pair.key} and skips the existing closer', () {
      var current = type(value(''), pair.key);
      expect(current.text, '${pair.key}${pair.value}');
      expect(current.selection.extentOffset, 1);
      current = type(current, 'x');
      current = type(current, pair.value);
      expect(current.text, '${pair.key}x${pair.value}');
      expect(current.selection.extentOffset, 3);
    });
  }

  test('inserting brackets in the middle preserves the suffix', () {
    final result = type(value('print', 2), '(');
    expect(result.text, 'pr()int');
    expect(result.selection.extentOffset, 3);
  });

  test('paste is not modified', () {
    final pasted = value('if x:\n    print(x)\nelse:\n    print(0)');
    expect(formatter.formatEditUpdate(value(''), pasted), pasted);
  });

  test('cursor movement does not add indentation', () {
    final old = value('if x:\n    ');
    final moved = value(old.text, 6);
    expect(formatter.formatEditUpdate(old, moved), moved);
  });

  test('selection deletion does not reinsert spaces', () {
    final old = TextEditingValue(
      text: 'if x:\n    ',
      selection: const TextSelection(baseOffset: 6, extentOffset: 10),
    );
    final deletion = value('if x:\n');
    expect(formatter.formatEditUpdate(old, deletion), deletion);
  });

  test('IME composition is preserved', () {
    final composing = value('(').copyWith(
      composing: const TextRange(start: 0, end: 1),
    );
    expect(formatter.formatEditUpdate(value(''), composing), composing);
  });
}
