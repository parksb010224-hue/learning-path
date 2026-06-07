import 'package:flutter/material.dart';
import 'problem_list_screen.dart';
import '../core/recommendation_api.dart';
import '../models/recommended_problem.dart';
import '../core/analysis_api.dart';
import '../models/ai_analysis.dart';
import '../core/recommendation_feedback_api.dart';

class AnalysisScreen extends StatefulWidget {
  final int submissionId;
  final int userId;
  final bool fromHistory;

  const AnalysisScreen({
    super.key,
    required this.submissionId,
    required this.userId,
    this.fromHistory = false,
  });

  @override
  State<AnalysisScreen> createState() => _AnalysisScreenState();
}

class _AnalysisScreenState extends State<AnalysisScreen> {
  late Future<AIAnalysis> futureAnalysis;
  late Future<List<RecommendedProblem>> futureRecommendations;

  @override
  void initState() {
    super.initState();
    futureAnalysis = _loadAnalysis();
    futureRecommendations =
        RecommendationApi.fetchAiRecommendations(widget.submissionId);
  }

  Future<AIAnalysis> _loadAnalysis() async {
    try {
      return await AnalysisApi.getAnalysis(widget.submissionId);
    } catch (_) {
      return await AnalysisApi.analyze(widget.submissionId);
    }
  }

  Widget section({
    required IconData icon,
    required String title,
    required String content,
    Color color = Colors.blue,
  }) {
    return Card(
      elevation: 3,
      margin: const EdgeInsets.only(bottom: 14),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              backgroundColor: color.withOpacity(0.12),
              child: Icon(icon, color: color),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    content.isEmpty ? '내용 없음' : content,
                    style: const TextStyle(
                      fontSize: 14,
                      height: 1.5,
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

  Widget recommendationSection() {
    return FutureBuilder<List<RecommendedProblem>>(
      future: futureRecommendations,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Text('추천 문제를 불러오는 중입니다...'),
            ),
          );
        }

        if (snapshot.hasError) {
          return Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                '추천 문제 불러오기 오류: ${snapshot.error}',
              ),
            ),
          );
        }

        final recommendations = snapshot.data ?? [];

        if (recommendations.isEmpty) {
          return const SizedBox();
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),
            const Text(
              'AI 추천 문제',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),

            ...recommendations.map((problem) {
              return Card(
                elevation: 3,
                margin: const EdgeInsets.only(bottom: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const CircleAvatar(
                            child: Icon(Icons.route),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              problem.title,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 10),

                      Text(
                        '${problem.difficulty} · ${problem.category}',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      const SizedBox(height: 8),

                      Text(
                        problem.reason,
                        style: const TextStyle(height: 1.4),
                      ),

                      const SizedBox(height: 10),

                      Row(
                        children: [
                          TextButton.icon(
                            onPressed: () async {
                              await RecommendationFeedbackApi.sendFeedback(
                                userId: widget.userId,
                                submissionId: widget.submissionId,
                                recommendedProblemId: problem.id,
                                feedback: 'HELPFUL',
                              );

                              if (!context.mounted) return;

                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('도움됨 피드백이 저장되었습니다.'),
                                ),
                              );
                            },
                            icon: const Icon(Icons.thumb_up_alt_outlined),
                            label: const Text('도움됨'),
                          ),
                          TextButton.icon(
                            onPressed: () async {
                              await RecommendationFeedbackApi.sendFeedback(
                                userId: widget.userId,
                                submissionId: widget.submissionId,
                                recommendedProblemId: problem.id,
                                feedback: 'NOT_HELPFUL',
                              );

                              if (!context.mounted) return;

                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('별로예요 피드백이 저장되었습니다.'),
                                ),
                              );
                            },
                            icon: const Icon(Icons.thumb_down_alt_outlined),
                            label: const Text('별로예요'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            }),
          ],
        );
      },
    );
  }

  Widget header() {
    return Container(
      padding: const EdgeInsets.all(18),
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: const LinearGradient(
          colors: [
            Color(0xFF4F7CFF),
            Color(0xFF6C63FF),
          ],
        ),
      ),
      child: const Row(
        children: [
          Icon(Icons.auto_awesome, color: Colors.white, size: 32),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              'AI가 제출 코드를 분석했습니다.\n오답 원인과 개선 방향을 확인하세요.',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                height: 1.4,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      appBar: AppBar(
        title: const Text('AI 분석 결과'),
        actions: [
          IconButton(
            tooltip: '문제 목록',
            icon: const Icon(Icons.home),
            onPressed: () {
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(
                  builder: (_) => ProblemListScreen(userId: widget.userId),
                ),
                    (route) => false,
              );
            },
          ),
        ],
      ),
      body: FutureBuilder<AIAnalysis>(
        future: futureAnalysis,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('분석 오류: ${snapshot.error}'));
          }

          if (!snapshot.hasData) {
            return const Center(child: Text('분석 결과가 없습니다.'));
          }

          final a = snapshot.data!;

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              header(),
              section(
                icon: Icons.error_outline,
                title: '오답 유형',
                content: a.wrongType,
                color: Colors.red,
              ),
              section(
                icon: Icons.psychology,
                title: '전체 분석',
                content: a.analysisText,
                color: Colors.indigo,
              ),
              section(
                icon: Icons.lightbulb_outline,
                title: '힌트 1',
                content: a.hint1,
                color: Colors.amber,
              ),
              section(
                icon: Icons.tips_and_updates,
                title: '힌트 2',
                content: a.hint2,
                color: Colors.orange,
              ),
              section(
                icon: Icons.school,
                title: '힌트 3',
                content: a.hint3,
                color: Colors.deepOrange,
              ),
              section(
                icon: Icons.restart_alt,
                title: '재도전 가이드',
                content: a.retryGuide,
                color: Colors.green,
              ),
              section(
                icon: Icons.speed,
                title: '시간복잡도',
                content: a.timeComplexity,
                color: Colors.purple,
              ),
              section(
                icon: Icons.build_circle_outlined,
                title: '개선 방향',
                content: a.improvementSuggestion,
                color: Colors.teal,
              ),
              section(
                icon: Icons.bug_report_outlined,
                title: '반례',
                content: a.counterExample,
                color: Colors.brown,
              ),
              recommendationSection(),
            ],
          );
        },
      ),
    );
  }
}