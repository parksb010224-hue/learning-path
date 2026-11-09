// 파일 역할: 문제 필터링과 Python 코드 입력 보조 기능: python code input formatter
// 주요 선언부에는 담당 기능을 설명하는 한국어 주석을 추가했습니다.
import 'package:flutter/services.dart';

/// Applies editor conveniences only to a newly inserted single character.
/// Deletions, paste, cursor moves and IME composition retain the user's value.
class PythonCodeInputFormatter extends TextInputFormatter {
  const PythonCodeInputFormatter();

  static const _pairs = {'(': ')', '{': '}', '[': ']'};

  @override
  /// formatEditUpdate: 이 기능의 화면 상태·요청·데이터 처리를 담당합니다.
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (!oldValue.selection.isValid ||
        !newValue.selection.isValid ||
        !oldValue.selection.isCollapsed ||
        !newValue.selection.isCollapsed ||
        (oldValue.composing.isValid && !oldValue.composing.isCollapsed) ||
        (newValue.composing.isValid && !newValue.composing.isCollapsed)) {
      return newValue;
    }

    final offset = oldValue.selection.extentOffset;
    if (offset > oldValue.text.length ||
        newValue.text.length != oldValue.text.length + 1 ||
        newValue.selection.extentOffset != offset + 1 ||
        newValue.text.substring(0, offset) !=
            oldValue.text.substring(0, offset) ||
        newValue.text.substring(offset + 1) !=
            oldValue.text.substring(offset)) {
      return newValue;
    }

    final inserted = newValue.text.substring(offset, offset + 1);
    if (inserted == '\n') {
      final before = oldValue.text.substring(0, offset);
      final previousLine = before.substring(before.lastIndexOf('\n') + 1);
      final leadingWhitespace =
          RegExp(r'^[ \t]*').firstMatch(previousLine)!.group(0)!;
      final indent = leadingWhitespace +
          (previousLine.trimRight().endsWith(':') ? '    ' : '');
      if (indent.isEmpty) return newValue;
      return newValue.copyWith(
        text: newValue.text.replaceRange(offset + 1, offset + 1, indent),
        selection: TextSelection.collapsed(offset: offset + 1 + indent.length),
        composing: TextRange.empty,
      );
    }

    final closing = _pairs[inserted];
    if (closing != null) {
      return newValue.copyWith(
        text: newValue.text.replaceRange(offset + 1, offset + 1, closing),
        selection: TextSelection.collapsed(offset: offset + 1),
        composing: TextRange.empty,
      );
    }

    // Typing an existing auto-inserted closing bracket moves past it.
    if (_pairs.containsValue(inserted) &&
        offset < oldValue.text.length &&
        oldValue.text.substring(offset, offset + 1) == inserted) {
      return newValue.copyWith(
        text: oldValue.text,
        selection: TextSelection.collapsed(offset: offset + 1),
        composing: TextRange.empty,
      );
    }
    return newValue;
  }
}
