// 파일 역할: Flutter 단위·위젯 테스트: problem filters test
// 주요 선언부에는 담당 기능을 설명하는 한국어 주석을 추가했습니다.
import 'package:flutter_test/flutter_test.dart';
import '../lib/models/problem.dart';
import '../lib/utils/problem_filters.dart';

/// main: 이 기능의 화면 상태·요청·데이터 처리를 담당합니다.
void main() {
  final problems = <Problem>[];
  for (final level in ['easy', 'medium', 'hard']) {
    for (final solved in [true, false]) {
      problems.add(Problem(
        id: problems.length + 1, title: level, difficulty: level,
        category: '', description: '', examples: [], isSolved: solved,
      ));
    }
  }
  for (final difficulty in DifficultyFilter.values) {
    for (final solved in SolvedFilter.values) {
      test('combines $difficulty and $solved', () {
        final result = filterProblems(problems, difficulty: difficulty, solved: solved);
        final levels = difficulty == DifficultyFilter.all ? 3 : 1;
        final statuses = solved == SolvedFilter.all ? 2 : 1;
        expect(result.length, levels * statuses);
        expect(result.every((p) =>
            (difficulty == DifficultyFilter.all || p.difficulty == difficulty.name) &&
            (solved == SolvedFilter.all || p.isSolved == (solved == SolvedFilter.solved))), isTrue);
        expect(problems.length, 6);
      });
    }
  }
  test('handles normalized Korean difficulty values', () {
    expect(normalizeDifficulty(' EASY '), 'easy');
    expect(normalizeDifficulty('쉬움'), 'easy');
    expect(normalizeDifficulty('보통'), 'medium');
    expect(normalizeDifficulty('어려움'), 'hard');
  });
  test('empty source returns empty results', () {
    expect(filterProblems([], difficulty: DifficultyFilter.hard,
        solved: SolvedFilter.solved), isEmpty);
  });
}
