import 'package:flutter/material.dart';
import 'analysis_screen.dart';
import '../models/submission_response.dart';
import 'problem_list_screen.dart';

class SubmissionResultScreen extends StatelessWidget {
  final SubmissionResponse result;
  final int userId;

  const SubmissionResultScreen({
    super.key,
    required this.result,
    required this.userId,
  });

  @override
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
                      ),
                    ),
                  );
                },
              ),
            ),

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
                        '테스트케이스 ${item.testCaseId}',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text(
                        '결과: ${item.result}\n'
                            '내 출력: ${item.actualOutput}\n'
                            '정답 출력: ${item.expectedOutput}',
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