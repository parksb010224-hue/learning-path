// 파일 역할: 사용자에게 표시되는 Flutter 화면과 입력·상태 처리: submission history screen
// 주요 선언부에는 담당 기능을 설명하는 한국어 주석을 추가했습니다.
import 'review_list_screen.dart';
import 'submission_code_screen.dart';
import 'package:flutter/material.dart';
import '../core/submission_history_api.dart';
import '../models/submission_history.dart';
import 'analysis_screen.dart';
import 'statistics_screen.dart';

/// SubmissionHistoryScreen: 해당 기능을 표시하는 화면 위젯입니다.
class SubmissionHistoryScreen extends StatelessWidget {
  final int userId;

  const SubmissionHistoryScreen({
    super.key,
    required this.userId,
  });

  /// verdictColor: 이 기능의 화면 상태·요청·데이터 처리를 담당합니다.
  Color verdictColor(String verdict) {
    if (verdict == 'ACCEPTED') return Colors.green;
    if (verdict == 'WRONG_ANSWER') return Colors.red;
    return Colors.orange;
  }

  /// verdictText: 이 기능의 화면 상태·요청·데이터 처리를 담당합니다.
  String verdictText(String verdict) {
    if (verdict == 'ACCEPTED') return '정답';
    if (verdict == 'WRONG_ANSWER') return '오답';
    if (verdict == 'RUNTIME_ERROR') return '런타임 에러';
    if (verdict == 'TIME_LIMIT_EXCEEDED') return '시간 초과';
    return verdict;
  }

  /// verdictIcon: 이 기능의 화면 상태·요청·데이터 처리를 담당합니다.
  IconData verdictIcon(String verdict) {
    if (verdict == 'ACCEPTED') return Icons.check_circle;
    if (verdict == 'WRONG_ANSWER') return Icons.cancel;
    return Icons.warning;
  }

  @override
  /// build: 화면 위젯 구조를 구성합니다.
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('제출 기록'),
        actions: [
          IconButton(
            tooltip: '오답 복습', icon: const Icon(Icons.menu_book),
            onPressed: () => Navigator.push(context, MaterialPageRoute(
              builder: (_) => ReviewListScreen(userId: userId),
            )),
          ),
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
                          verdict: s.verdict,
                          problemId: s.problemId,
                          submittedCode: s.sourceCode,
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
                                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                s.createdAt,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                                ),
                              ),
                              TextButton.icon(
                                onPressed: () => Navigator.push(context, MaterialPageRoute(
                                  builder: (_) => SubmissionCodeScreen(
                                    userId: userId, submissionId: s.id,
                                  ),
                                )),
                                icon: const Icon(Icons.code), label: const Text('제출 코드 보기'),
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