// 파일 역할: Flutter 단위·위젯 테스트: problem search test
// 주요 선언부에는 담당 기능을 설명하는 한국어 주석을 추가했습니다.
import 'package:flutter_test/flutter_test.dart';
import '../lib/models/problem.dart';
import '../lib/utils/problem_filters.dart';

/// p: 이 기능의 화면 상태·요청·데이터 처리를 담당합니다.
Problem p(int id, String title, String category, String difficulty, bool solved) =>
    Problem(id: id, title: title, category: category, difficulty: difficulty,
      isSolved: solved, description: '', examples: []);
/// main: 이 기능의 화면 상태·요청·데이터 처리를 담당합니다.
void main() {
  final problems = [
    p(1, '문자열 뒤집기', '문자열', 'easy', false),
    p(2, '문자열 길이', '문자열', 'medium', true),
    p(3, 'Stone Game', 'DP', 'hard', false),
    p(4, 'Other Game', ' dp ', 'easy', true),
    p(5, '미분류 문제', '', 'easy', false),
  ];
  test('search combines all filters', () {
    final found = filterProblems(problems, difficulty: DifficultyFilter.easy,
      solved: SolvedFilter.unsolved, category: '문자열', query: ' 뒤집기 문자열 ');
    expect(found.map((p) => p.id), [1]);
  });
  test('search ignores case and supports title or category', () {
    expect(filterProblems(problems, difficulty: DifficultyFilter.all,
      solved: SolvedFilter.all, query: 'gAmE DP').map((p) => p.id), [3, 4]);
  });
  test('categories are deduplicated and include uncategorized', () {
    final categories = availableProblemCategories(problems);
    expect(categories.where((c) => c.toLowerCase() == 'dp').length, 1);
    expect(categories, contains('미분류'));
  });
  test('empty search returns all, no match returns empty', () {
    expect(filterProblems(problems, difficulty: DifficultyFilter.all,
      solved: SolvedFilter.all, query: '  ').length, problems.length);
    expect(filterProblems(problems, difficulty: DifficultyFilter.all,
      solved: SolvedFilter.all, query: 'does not exist'), isEmpty);
  });
}
