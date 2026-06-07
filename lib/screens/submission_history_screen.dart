import 'package:flutter/material.dart';
import '../core/submission_history_api.dart';
import '../models/submission_history.dart';
import 'analysis_screen.dart';
import 'statistics_screen.dart';

class SubmissionHistoryScreen extends StatelessWidget {
  final int userId;

  const SubmissionHistoryScreen({
    super.key,
    required this.userId,
  });

  Color verdictColor(String verdict) {
    if (verdict == 'ACCEPTED') return Colors.green;
    if (verdict == 'WRONG_ANSWER') return Colors.red;
    return Colors.orange;
  }

  String verdictText(String verdict) {
    if (verdict == 'ACCEPTED') return '정답';
    if (verdict == 'WRONG_ANSWER') return '오답';
    if (verdict == 'RUNTIME_ERROR') return '런타임 에러';
    if (verdict == 'TIME_LIMIT_EXCEEDED') return '시간 초과';
    return verdict;
  }

  IconData verdictIcon(String verdict) {
    if (verdict == 'ACCEPTED') return Icons.check_circle;
    if (verdict == 'WRONG_ANSWER') return Icons.cancel;
    return Icons.warning;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      appBar: AppBar(
        title: const Text('제출 기록'),
        actions: [
          IconButton(
            icon: const Icon(Icons.bar_chart),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => StatisticsScreen(userId: userId),
                ),
              );
            },
          ),
        ],
      ),
      body: FutureBuilder<List<SubmissionHistory>>(
        future: SubmissionHistoryApi.fetchSubmissions(userId: userId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('오류: ${snapshot.error}'));
          }

          final submissions = snapshot.data ?? [];

          if (submissions.isEmpty) {
            return const Center(child: Text('제출 기록이 없습니다.'));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: submissions.length,
            itemBuilder: (context, index) {
              final s = submissions[index];
              final color = verdictColor(s.verdict);

              return Card(
                elevation: 3,
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
                child: InkWell(
                  borderRadius: BorderRadius.circular(18),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => AnalysisScreen(
                          submissionId: s.id,
                          userId: userId,
                          fromHistory: true,
                        ),
                      ),
                    );
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Icon(
                          verdictIcon(s.verdict),
                          color: color,
                          size: 34,
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                s.problemTitle,
                                style: const TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                '${s.language} · ${s.passedCount}/${s.totalCount} 통과',
                                style: TextStyle(
                                  color: Colors.grey[700],
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                s.createdAt,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[500],
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: color.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            verdictText(s.verdict),
                            style: TextStyle(
                              color: color,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}