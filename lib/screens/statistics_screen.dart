import 'package:flutter/material.dart';
import '../core/submission_history_api.dart';
import '../models/submission_history.dart';
import 'problem_list_screen.dart';

class StatisticsScreen extends StatelessWidget {
  final int userId;

  const StatisticsScreen({
    super.key,
    required this.userId,
  });

  Widget statCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: color.withOpacity(0.12),
              child: Icon(icon, color: color),
            ),
            const SizedBox(width: 14),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(color: Colors.grey[600]),
                ),
                const SizedBox(height: 6),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String getLearningFeedback(int rate) {
    if (rate >= 80) {
      return '잘하고 있습니다. Medium 문제에 도전해보세요.';
    } else if (rate >= 50) {
      return '기초는 잡혀 있습니다. 오답 문제를 다시 복습해보세요.';
    } else {
      return 'Easy 문제와 AI 추천 문제를 먼저 풀어보세요.';
    }
  }

  Widget feedbackCard(String feedback) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              backgroundColor: Colors.orange.withOpacity(0.12),
              child: const Icon(
                Icons.tips_and_updates,
                color: Colors.orange,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '학습 피드백',
                    style: TextStyle(
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    feedback,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      appBar: AppBar(
        title: const Text('학습 통계'),
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
      body: FutureBuilder<List<SubmissionHistory>>(
        future: SubmissionHistoryApi.fetchSubmissions(userId: userId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Text('오류: ${snapshot.error}'),
            );
          }

          final submissions = snapshot.data ?? [];

          final total = submissions.length;

          final accepted =
              submissions.where((s) => s.verdict == 'ACCEPTED').length;

          final wrong =
              submissions.where((s) => s.verdict == 'WRONG_ANSWER').length;

          final rate =
          total == 0 ? 0 : ((accepted / total) * 100).round();

          final feedback = getLearningFeedback(rate);

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(22),
                  gradient: const LinearGradient(
                    colors: [
                      Color(0xFF4F7CFF),
                      Color(0xFF6C63FF),
                    ],
                  ),
                ),
                child: const Text(
                  '나의 학습 현황을 한눈에 확인하세요.',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),

              statCard(
                title: '총 제출 수',
                value: '$total회',
                icon: Icons.upload_file,
                color: Colors.blue,
              ),

              statCard(
                title: '정답 수',
                value: '$accepted회',
                icon: Icons.check_circle,
                color: Colors.green,
              ),

              statCard(
                title: '오답 수',
                value: '$wrong회',
                icon: Icons.cancel,
                color: Colors.red,
              ),

              statCard(
                title: '정답률',
                value: '$rate%',
                icon: Icons.percent,
                color: Colors.purple,
              ),

              const SizedBox(height: 12),

              feedbackCard(feedback),
            ],
          );
        },
      ),
    );
  }
}