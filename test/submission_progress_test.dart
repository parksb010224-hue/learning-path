// 파일 역할: Flutter 단위·위젯 테스트: submission progress test
// 주요 선언부에는 담당 기능을 설명하는 한국어 주석을 추가했습니다.
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:untitled/core/submission_api.dart';
import 'package:untitled/models/submission_progress.dart';
import 'package:untitled/screens/submission_progress_screen.dart';

/// snapshot: 이 기능의 화면 상태·요청·데이터 처리를 담당합니다.
Map<String, dynamic> snapshot({String status = 'RUNNING'}) => {
  'job_id': 'same-job', 'status': status, 'total_count': 2,
  'completed_count': status == 'COMPLETED' ? 2 : 1,
  'passed_count': status == 'COMPLETED' ? 2 : 1,
  'cases': [
    {'number': 1, 'is_sample': true, 'result': 'ACCEPTED'},
    {'number': 2, 'is_sample': false, 'result': status == 'COMPLETED' ? 'ACCEPTED' : 'RUNNING'},
  ],
  'error': null,
  'result': status != 'COMPLETED' ? null : {
    'submission_id': 38, 'verdict': 'ACCEPTED', 'passed_count': 2,
    'total_count': 2, 'results': [
      {'test_case_id': 1, 'result': 'ACCEPTED', 'is_sample': true,
        'actual_output': '3', 'expected_output': '3'},
      {'test_case_id': 2, 'result': 'ACCEPTED', 'is_sample': false,
        'actual_output': null, 'expected_output': null},
    ],
  },
};

/// main: 이 기능의 화면 상태·요청·데이터 처리를 담당합니다.
void main() {
  test('acceptance sends idempotency key; status read never resends source', () async {
    final requests = <http.Request>[];
    final client = MockClient((request) async {
      requests.add(request);
      return http.Response(jsonEncode(snapshot()), request.method == 'POST' ? 202 : 200);
    });
    await SubmissionApi.startSubmission(userId: 6, problemId: 1,
      sourceCode: 'print(3)', requestKey: List.filled(32, 'a').join(), client: client);
    await SubmissionApi.fetchProgress(jobId: 'same-job', userId: 6, client: client);
    expect(jsonDecode(requests.first.body)['request_key'], List.filled(32, 'a').join());
    expect(requests.last.method, 'GET');
    expect(requests.last.url.queryParameters['user_id'], '6');
    expect(requests.last.body, isEmpty);
  });

  test('lookup surfaces server error detail', () async {
    final client = MockClient((_) async => http.Response(
      jsonEncode({'detail': '[JUDGE_BUSY] busy'}), 503));
    await expectLater(SubmissionApi.fetchProgress(jobId: 'same-job', userId: 6, client: client),
      throwsA(predicate((e) => e.toString().contains('[JUDGE_BUSY]'))));
  });

  testWidgets('shows completed and running cases and recovers without resubmitting', (tester) async {
    var starts = 0;
    var reads = 0;
    await tester.pumpWidget(MaterialApp(home: SubmissionProgressScreen(
      userId: 6, problemId: 1, sourceCode: 'print(3)', problemTitle: 'A+B',
      startJob: (_) async { starts++; return SubmissionProgress.fromJson(snapshot()); },
      loadJob: (id) async {
        expect(id, 'same-job');
        reads++;
        if (reads == 1) throw Exception('temporary network failure');
        return SubmissionProgress.fromJson(snapshot(status: 'COMPLETED'));
      },
    )));
    await tester.pump();
    expect(find.text('테스트 1/2 — 정답'), findsOneWidget);
    expect(find.text('테스트 2/2 — 채점 중'), findsOneWidget);
    expect(find.text('비공개 테스트'), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 710));
    await tester.pump();
    expect(find.text('진행 상태 다시 조회'), findsOneWidget);
    await tester.tap(find.text('진행 상태 다시 조회'));
    await tester.pumpAndSettle();
    expect(starts, 1);
    expect(reads, 2);
    expect(find.text('채점 완료 2 / 2'), findsOneWidget);
    expect(find.text('제출 결과 보기'), findsOneWidget);
    // Output values are reserved for the final result screen.
    expect(find.text('3'), findsNothing);
  });

  testWidgets('lost acceptance response retries using the identical key', (tester) async {
    final keys = <String>[];
    await tester.pumpWidget(MaterialApp(home: SubmissionProgressScreen(
      userId: 6, problemId: 1, sourceCode: 'print(3)', problemTitle: 'A+B',
      startJob: (key) async {
        keys.add(key);
        if (keys.length == 1) throw Exception('response lost');
        return SubmissionProgress.fromJson(snapshot(status: 'COMPLETED'));
      },
    )));
    await tester.pump();
    await tester.tap(find.text('접수 다시 확인'));
    await tester.pumpAndSettle();
    expect(keys.length, 2);
    expect(keys.first, keys.last);
    expect(find.text('제출 결과 보기'), findsOneWidget);
  });
}
