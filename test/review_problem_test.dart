// 파일 역할: Flutter 단위·위젯 테스트: review problem test
// 주요 선언부에는 담당 기능을 설명하는 한국어 주석을 추가했습니다.
import 'package:flutter_test/flutter_test.dart';
import '../lib/models/problem.dart';
import '../lib/models/submission_history.dart';
import '../lib/models/review_problem.dart';

/// p: 이 기능의 화면 상태·요청·데이터 처리를 담당합니다.
Problem p(int id, {bool solved = false}) => Problem(
  id: id, title: 'problem $id', category: 'DP', difficulty: 'easy',
  description: '', examples: [], isSolved: solved,
);
/// s: 이 기능의 화면 상태·요청·데이터 처리를 담당합니다.
SubmissionHistory s(int id, int problemId, String verdict) => SubmissionHistory(
  id: id, problemId: problemId, problemTitle: 'history $problemId',
  verdict: verdict, language: 'python', passedCount: 0, totalCount: 1, createdAt: '',
);
/// main: 이 기능의 화면 상태·요청·데이터 처리를 담당합니다.
void main() {
  test('only unsolved attempted problems appear once, newest first', () {
    final rows = buildReviewProblems([
      s(1, 1, 'WRONG_ANSWER'), s(5, 2, 'RUNTIME_ERROR'),
      s(3, 1, 'TIME_LIMIT_EXCEEDED'), s(2, 3, 'WRONG_ANSWER'),
      s(4, 3, 'ACCEPTED'), s(6, 3, 'WRONG_ANSWER'),
    ], [p(1), p(2), p(3), p(4)]);
    expect(rows.map((row) => row.problemId), [2, 1]);
    expect(rows.last.failureCount, 2);
    expect(rows.last.latestSubmission.id, 3);
    expect(rows.last.category, 'DP');
  });
  test('a subsequent acceptance removes a problem from review', () {
    final history = [s(1, 1, 'WRONG_ANSWER')];
    expect(buildReviewProblems(history, [p(1)]).length, 1);
    history.add(s(2, 1, 'ACCEPTED'));
    expect(buildReviewProblems(history, [p(1)]), isEmpty);
  });
  test('server solved status also excludes partial-history rows', () {
    expect(buildReviewProblems([s(1, 1, 'WRONG_ANSWER')], [p(1, solved: true)]), isEmpty);
  });
  test('empty records and missing problem metadata are safe', () {
    expect(buildReviewProblems([], [p(1)]), isEmpty);
    final rows = buildReviewProblems([s(1, 9, 'WRONG_ANSWER')], []);
    expect(rows.single.category, '미분류');
    expect(rows.single.title, 'history 9');
  });
}
