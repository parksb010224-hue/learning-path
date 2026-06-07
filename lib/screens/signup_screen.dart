import 'package:flutter/material.dart';
class ResultScreen extends StatelessWidget {
  final Problem problem;
  final SubmissionResponse submission;
  final String sourceCode;

  const ResultScreen({
    super.key,
    required this.problem,
    required this.submission,
    required this.sourceCode,
  });

  @override
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