// 파일 역할: API 응답 데이터 모델 및 JSON 직렬화: review problem
// 주요 선언부에는 담당 기능을 설명하는 한국어 주석을 추가했습니다.
import 'problem.dart';
import 'submission_history.dart';
import '../utils/problem_filters.dart';

/// ReviewProblem: 이 기능의 화면 상태·요청·데이터 처리를 담당합니다.
class ReviewProblem {
  final int problemId;
  final String title;
  final String category;
  final String difficulty;
  final int failureCount;
  final SubmissionHistory latestSubmission;
  const ReviewProblem({required this.problemId, required this.title,
    required this.category, required this.difficulty, required this.failureCount,
    required this.latestSubmission});
}

/// buildReviewProblems: 이 기능의 화면 상태·요청·데이터 처리를 담당합니다.
List<ReviewProblem> buildReviewProblems(List<SubmissionHistory> history, List<Problem> problems) {
  final byId = {for (final problem in problems) problem.id: problem};
  final solved = {
    ...history.where((row) => row.verdict == 'ACCEPTED').map((row) => row.problemId),
    ...problems.where((problem) => problem.isSolved).map((problem) => problem.id),
  };
  final groups = <int, List<SubmissionHistory>>{};
  for (final row in history) {
    if (!solved.contains(row.problemId)) groups.putIfAbsent(row.problemId, () => []).add(row);
  }
  final result = groups.entries.map((entry) {
    // Submission IDs increase at insertion time, including rows without dates.
    final rows = entry.value..sort((a, b) => b.id.compareTo(a.id));
    final latest = rows.first;
    final problem = byId[entry.key];
    return ReviewProblem(
      problemId: entry.key,
      title: problem?.title ?? latest.problemTitle,
      category: problemCategoryLabel(problem?.category ?? ''),
      difficulty: problem?.difficulty ?? '',
      failureCount: rows.where((row) => row.verdict != 'ACCEPTED').length,
      latestSubmission: latest,
    );
  }).toList()..sort((a, b) => b.latestSubmission.id.compareTo(a.latestSubmission.id));
  return result;
}
