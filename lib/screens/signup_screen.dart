// 파일 역할: 사용자에게 표시되는 Flutter 화면과 입력·상태 처리: signup screen
// 주요 선언부에는 담당 기능을 설명하는 한국어 주석을 추가했습니다.
import 'package:flutter/material.dart';
import '../models/problem.dart';
import '../models/submission_response.dart';
import 'analysis_screen.dart';
/// ResultScreen: 해당 기능을 표시하는 화면 위젯입니다.
class ResultScreen extends StatelessWidget {
  final Problem problem;
  final SubmissionResponse submission;
  final String sourceCode;
  final int userId;

  const ResultScreen({
    super.key,
    required this.problem,
    required this.submission,
    required this.sourceCode,
    required this.userId,
  });

  @override
  /// build: 화면 위젯 구조를 구성합니다.
  Widget build(BuildContext context) {
    final isAccepted = submission.verdict == 'ACCEPTED';

    return Scaffold(
      appBar: AppBar(title: const Text('제출 결과')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text(
              '판정: ${submission.verdict}',
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            Text('통과: ${submission.passedCount}/${submission.totalCount}'),
            const SizedBox(height: 16),
            Expanded(
              child: ListView.builder(
                itemCount: submission.results.length,
                itemBuilder: (context, index) {
                  final r = submission.results[index];
                  return Card(
                    child: ListTile(
                      title: Text('테스트케이스 ${index + 1}'),
                      subtitle: Text(r.result),
                    ),
                  );
                },
              ),
            ),
            if (!isAccepted)
              ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => AnalysisScreen(
                        submissionId: submission.submissionId,
                        userId: userId,
                        verdict: submission.verdict,
                        problemId: problem.id,
                        problem: problem,
                        submittedCode: sourceCode,
                      ),
                    ),
                  );
                },
                child: const Text('AI 오답 분석 보기'),
              ),
          ],
        ),
      ),
    );
  }
}