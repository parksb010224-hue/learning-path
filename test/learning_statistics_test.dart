// 파일 역할: Flutter 단위·위젯 테스트: learning statistics test
// 주요 선언부에는 담당 기능을 설명하는 한국어 주석을 추가했습니다.
import 'package:flutter_test/flutter_test.dart';
import '../lib/models/problem.dart';
import '../lib/models/submission_history.dart';
import '../lib/models/learning_statistics.dart';

/// p: 이 기능의 화면 상태·요청·데이터 처리를 담당합니다.
Problem p(int id, String category) => Problem(id: id, title: '', category: category,
  difficulty: 'easy', description: '', examples: [], isSolved: false);
/// s: 이 기능의 화면 상태·요청·데이터 처리를 담당합니다.
SubmissionHistory s(int id, int problemId, String verdict) => SubmissionHistory(
  id: id, problemId: problemId, verdict: verdict, problemTitle: '', language: 'python',
  passedCount: 0, totalCount: 1, createdAt: '',
);
/// main: 이 기능의 화면 상태·요청·데이터 처리를 담당합니다.
void main() {
  test('counts unique solved problems and includes later failed attempts', () {
    final stats = LearningStatistics.fromData([
      s(1, 1, 'WRONG_ANSWER'), s(2, 1, 'ACCEPTED'),
      s(3, 1, 'ACCEPTED'), s(4, 1, 'WRONG_ANSWER'), s(5, 2, 'RUNTIME_ERROR'),
    ], [p(1, 'DP'), p(2, ' dp '), p(3, '문자열')]);
    expect(stats.submissions, 5);
    expect(stats.accepted, 2);
    expect(stats.failed, 3);
    expect(stats.solvedProblems, 1);
    expect(stats.attemptedProblems, 2);
    final dp = stats.categories.first;
    expect(dp.acceptanceRate, closeTo(0.4, 0.0001));
    expect(dp.solvedProblems, 1);
    expect(dp.unresolvedProblems, 1);
    expect(stats.categories.last.submissions, 0);
  });
  test('empty history is safe and unknown problems are uncategorized', () {
    final empty = LearningStatistics.fromData([], [p(1, 'DP')]);
    expect(empty.acceptanceRate, 0);
    expect(empty.categories.single.acceptanceRate, 0);
    final missing = LearningStatistics.fromData([s(1, 99, 'TIME_LIMIT_EXCEEDED')], []);
    expect(missing.categories.single.category, '미분류');
    expect(missing.failed, 1);
  });
}
