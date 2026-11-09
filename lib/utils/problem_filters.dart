// 파일 역할: 문제 필터링과 Python 코드 입력 보조 기능: problem filters
// 주요 선언부에는 담당 기능을 설명하는 한국어 주석을 추가했습니다.
import '../models/problem.dart';

/// DifficultyFilter: 이 기능의 화면 상태·요청·데이터 처리를 담당합니다.
enum DifficultyFilter { all, easy, medium, hard }
/// SolvedFilter: 이 기능의 화면 상태·요청·데이터 처리를 담당합니다.
enum SolvedFilter { all, solved, unsolved }

/// normalizeDifficulty: 이 기능의 화면 상태·요청·데이터 처리를 담당합니다.
String normalizeDifficulty(String difficulty) {
  switch (difficulty.trim().toLowerCase()) {
    case '쉬움': return 'easy';
    case '보통': return 'medium';
    case '어려움': return 'hard';
    default: return difficulty.trim().toLowerCase();
  }
}

/// filterProblems: 이 기능의 화면 상태·요청·데이터 처리를 담당합니다.
List<Problem> filterProblems(
  List<Problem> problems, {
  required DifficultyFilter difficulty,
  required SolvedFilter solved,
  String query = '',
  String? category,
}) {
  final terms = query.trim().toLowerCase().split(RegExp(r'\s+'))
      .where((term) => term.isNotEmpty);
  return problems.where((problem) {
    final matchesDifficulty = difficulty == DifficultyFilter.all ||
        normalizeDifficulty(problem.difficulty) == difficulty.name;
    final matchesSolved = solved == SolvedFilter.all ||
        (solved == SolvedFilter.solved ? problem.isSolved : !problem.isSolved);
    final matchesCategory = category == null ||
        problemCategoryKey(problem.category) == problemCategoryKey(category);
    final searchable = '${problem.title} ${problemCategoryLabel(problem.category)}'.toLowerCase();
    return matchesDifficulty && matchesSolved && matchesCategory &&
        terms.every((term) => searchable.contains(term));
  }).toList();
}

/// problemCategoryLabel: 이 기능의 화면 상태·요청·데이터 처리를 담당합니다.
String problemCategoryLabel(String category) =>
    category.trim().isEmpty ? '미분류' : category.trim();
/// problemCategoryKey: 이 기능의 화면 상태·요청·데이터 처리를 담당합니다.
String problemCategoryKey(String category) => problemCategoryLabel(category).toLowerCase();

/// availableProblemCategories: 이 기능의 화면 상태·요청·데이터 처리를 담당합니다.
List<String> availableProblemCategories(List<Problem> problems) {
  final labels = <String, String>{};
  for (final problem in problems) {
    labels.putIfAbsent(problemCategoryKey(problem.category),
        () => problemCategoryLabel(problem.category));
  }
  return labels.values.toList()..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
}
