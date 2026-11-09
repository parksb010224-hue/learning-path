// 파일 역할: 사용자에게 표시되는 Flutter 화면과 입력·상태 처리: submission result screen
// 주요 선언부에는 담당 기능을 설명하는 한국어 주석을 추가했습니다.
import 'submission_code_screen.dart';
import 'package:flutter/material.dart';
import 'analysis_screen.dart';
import 'problem_detail_screen.dart';
import '../models/problem.dart';
import '../models/submission_response.dart';
import 'problem_list_screen.dart';

/// SubmissionResultScreen: 해당 기능을 표시하는 화면 위젯입니다.
class SubmissionResultScreen extends StatelessWidget {
  final SubmissionResponse result;
  final int userId;
  final Problem problem;
  final String submittedCode;

  const SubmissionResultScreen({
    super.key,
    required this.result,
    required this.userId,
    required this.problem,
    required this.submittedCode,
  });

  @override
  /// build: 화면 위젯 구조를 구성합니다.
  Widget build(BuildContext context) {
    final isAccepted = result.verdict == 'ACCEPTED';

    return Scaffold(
      appBar: AppBar(
        title: const Text('제출 결과'),
        actions: [
          IconButton(
            tooltip: '문제 목록',
            icon: const Icon(Icons.home),
            onPressed: () {
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(
                  builder: (_) => ProblemListScreen(userId: userId),
                ),
                    (route) => false,
              );
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isAccepted ? '정답입니다!' : '오답입니다',
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
                color: isAccepted ? Colors.green : Colors.red,
              ),
            ),

            const SizedBox(height: 12),

            Text(
              '통과한 테스트케이스: ${result.passedCount} / ${result.totalCount}',
              style: const TextStyle(fontSize: 16),
            ),

            const SizedBox(height: 16),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.psychology),
                label: const Text('AI 분석 보기'),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => AnalysisScreen(
                        submissionId: result.submissionId,
                        userId: userId,
                        verdict: result.verdict,
                        problemId: problem.id,
                        problem: problem,
                        submittedCode: submittedCode,
                      ),
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                icon: const Icon(Icons.code), label: const Text('제출 코드 보기'),
                onPressed: () => Navigator.push(context, MaterialPageRoute(
                  builder: (_) => SubmissionCodeScreen(
                    userId: userId, submissionId: result.submissionId,
                  ),
                )),
              ),
            ),
            if (!isAccepted) ...[
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.refresh),
                  label: const Text('다시 풀기'),
                  onPressed: () {
                    Navigator.pushReplacement(context, MaterialPageRoute(
                      builder: (_) => ProblemDetailScreen(
                        problem: problem, userId: userId,
                        initialCode: submittedCode,
                      ),
                    ));
                  },
                ),
              ),
            ],
            const SizedBox(height: 20),

            const Text(
              '테스트케이스별 결과',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 10),

            Expanded(
              child: ListView.builder(
                itemCount: result.results.length,
                itemBuilder: (context, index) {
                  final item = result.results[index];
                  final accepted = item.result == 'ACCEPTED';

                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: ListTile(
                      title: Text(
                        '${item.isSample ? '공개 예제' : '비공개 테스트'} ${index + 1}',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text(
                        item.isSample
                            ? '결과: ${item.result}\n내 출력: ${item.actualOutput ?? ''}\n정답 출력: ${item.expectedOutput ?? ''}'
                                '${item.stderr == null || item.stderr!.isEmpty ? '' : '\n오류: ${item.stderr}'}'
                            : '결과: ${item.result}\n채점용 입력과 출력은 공개하지 않습니다.',
                      ),
                      trailing: Icon(
                        accepted ? Icons.check_circle : Icons.cancel,
                        color: accepted ? Colors.green : Colors.red,
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}