// 파일 역할: API 응답 데이터 모델 및 JSON 직렬화: learning statistics
// 주요 선언부에는 담당 기능을 설명하는 한국어 주석을 추가했습니다.
import 'problem.dart';
import 'submission_history.dart';
import '../utils/problem_filters.dart';

/// CategoryLearningStatistics: 이 기능의 화면 상태·요청·데이터 처리를 담당합니다.
class CategoryLearningStatistics {
  final String category;
  final int submissions;
  final int accepted;
  final int attemptedProblems;
  final int solvedProblems;
  const CategoryLearningStatistics({required this.category, required this.submissions,
    required this.accepted, required this.attemptedProblems, required this.solvedProblems});
  int get failed => submissions - accepted;
  int get unresolvedProblems => attemptedProblems - solvedProblems;
  double get acceptanceRate => submissions == 0 ? 0 : accepted / submissions;
}

/// LearningStatistics: 이 기능의 화면 상태·요청·데이터 처리를 담당합니다.
class LearningStatistics {
  final int submissions;
  final int accepted;
  final int attemptedProblems;
  final int solvedProblems;
  final List<CategoryLearningStatistics> categories;
  const LearningStatistics({required this.submissions, required this.accepted,
    required this.attemptedProblems, required this.solvedProblems, required this.categories});
  int get failed => submissions - accepted;
  double get acceptanceRate => submissions == 0 ? 0 : accepted / submissions;

  factory LearningStatistics.fromData(List<SubmissionHistory> history, List<Problem> problems) {
    final byId = {for (final problem in problems) problem.id: problem};
    final labels = <String, String>{};
    final groups = <String, List<SubmissionHistory>>{};
    for (final problem in problems) {
      final key = problemCategoryKey(problem.category);
      labels.putIfAbsent(key, () => problemCategoryLabel(problem.category));
      groups.putIfAbsent(key, () => []);
    }
    for (final row in history) {
      final category = byId[row.problemId]?.category ?? '';
      final key = problemCategoryKey(category);
      labels.putIfAbsent(key, () => problemCategoryLabel(category));
      groups.putIfAbsent(key, () => []).add(row);
    }
    final categories = groups.entries.map((entry) {
      final rows = entry.value;
      final accepted = rows.where((row) => row.verdict == 'ACCEPTED').toList();
      return CategoryLearningStatistics(
        category: labels[entry.key]!, submissions: rows.length,
        accepted: accepted.length,
        attemptedProblems: rows.map((row) => row.problemId).toSet().length,
        solvedProblems: accepted.map((row) => row.problemId).toSet().length,
      );
    }).toList()..sort((a, b) {
      final comparison = b.submissions.compareTo(a.submissions);
      return comparison != 0 ? comparison : a.category.compareTo(b.category);
    });
    final accepted = history.where((row) => row.verdict == 'ACCEPTED').toList();
    return LearningStatistics(
      submissions: history.length, accepted: accepted.length,
      attemptedProblems: history.map((row) => row.problemId).toSet().length,
      solvedProblems: accepted.map((row) => row.problemId).toSet().length,
      categories: List.unmodifiable(categories),
    );
  }
}
