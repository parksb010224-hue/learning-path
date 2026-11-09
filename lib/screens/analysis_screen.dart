// 파일 역할: AI 오답 분석과 단계별 힌트 표시 화면
// 주요 선언부에는 담당 기능을 설명하는 한국어 주석을 추가했습니다.
import 'dart:async';
import 'package:flutter/material.dart';
import 'problem_list_screen.dart';
import 'problem_detail_screen.dart';
import '../models/problem.dart';
import '../core/problem_api.dart';
import '../core/code_draft_store.dart';
import '../core/submission_api.dart';
import '../core/recommendation_api.dart';
import '../models/recommended_problem.dart';
import '../core/analysis_api.dart';
import '../models/ai_analysis.dart';
import '../widgets/progressive_hints.dart';
import '../core/recommendation_feedback_api.dart';

/// AnalysisScreen: 해당 기능을 표시하는 화면 위젯입니다.
class AnalysisScreen extends StatefulWidget {
  final int submissionId;
  final int userId;
  final String verdict;
  final int problemId;
  final Problem? problem;
  final String? submittedCode;
  final bool fromHistory;

  bool get isAccepted => verdict == 'ACCEPTED';

  const AnalysisScreen({
    super.key,
    required this.submissionId,
    required this.userId,
    required this.verdict,
    required this.problemId,
    this.problem,
    this.submittedCode,
    this.fromHistory = false,
  });

  @override
  /// createState: 이 기능의 화면 상태·요청·데이터 처리를 담당합니다.
  State<AnalysisScreen> createState() => _AnalysisScreenState();
}

/// _AnalysisScreenState: 화면/모델 내부에서만 사용하는 보조 처리입니다.
class _AnalysisScreenState extends State<AnalysisScreen> {
  bool _openingProblem = false;
  late Future<AIAnalysis> futureAnalysis;
  late Future<List<RecommendedProblem>> futureRecommendations;

  @override
  /// initState: 이 기능의 화면 상태·요청·데이터 처리를 담당합니다.
  void initState() {
    super.initState();
    futureAnalysis = _loadAnalysis();
    futureRecommendations = _loadRecommendations();
  }

  /// _loadRecommendations: 화면/모델 내부에서만 사용하는 보조 처리입니다.
  Future<List<RecommendedProblem>> _loadRecommendations() {
    final future = RecommendationApi.fetchAiRecommendations(
      widget.submissionId, verdict: widget.verdict,
    );
    // Recommendations can fail before the analysis builder subscribes.
    unawaited(future.then<void>((_) {}, onError: (Object error, StackTrace stack) {}));
    return future;
  }

  /// _loadAnalysis: 화면/모델 내부에서만 사용하는 보조 처리입니다.
  Future<AIAnalysis> _loadAnalysis() async {
    try {
      return await AnalysisApi.getAnalysis(widget.submissionId);
    } catch (_) {
      return await AnalysisApi.analyze(widget.submissionId);
    }
  }

  /// _openProblem: 화면/모델 내부에서만 사용하는 보조 처리입니다.
  Future<void> _openProblem(int problemId, {bool retry = false}) async {
    if (_openingProblem) return;
    setState(() => _openingProblem = true);
    try {
      final problem = retry && widget.problem != null
          ? widget.problem!
          : await ProblemApi.fetchProblemDetail(problemId);
      String? code;
      if (retry) {
        code = widget.submittedCode;
        if (code == null) {
          try {
            final submission = await SubmissionApi.fetchSubmission(
              userId: widget.userId, submissionId: widget.submissionId,
            );
            code = submission['source_code'] as String?;
          } catch (_) {
            // A locally saved snapshot remains usable while the API is offline.
          }
        }
        if (code == null) {
          try {
            code = await CodeDraftStore.instance.readSubmission(
              widget.userId, widget.submissionId,
            );
          } catch (_) {
            // ProblemDetailScreen will restore its problem draft instead.
          }
        }
      }
      if (!mounted) return;
      await Navigator.push(context, MaterialPageRoute(
        builder: (_) => ProblemDetailScreen(
          problem: problem, userId: widget.userId, initialCode: code,
        ),
      ));
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('문제를 불러오지 못했습니다. 다시 시도해주세요.')),
      );
    } finally {
      if (mounted) setState(() => _openingProblem = false);
    }
  }

  /// section: 이 기능의 화면 상태·요청·데이터 처리를 담당합니다.
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

  /// recommendationSection: 이 기능의 화면 상태·요청·데이터 처리를 담당합니다.
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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('AI 추천 문제를 불러오지 못했습니다.'),
                  TextButton.icon(
                    onPressed: () => setState(() {
                      futureRecommendations = _loadRecommendations();
                    }),
                    icon: const Icon(Icons.refresh), label: const Text('추천 다시 시도'),
                  ),
                ],
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
                child: InkWell(
                  borderRadius: BorderRadius.circular(18),
                  onTap: _openingProblem ? null : () => _openProblem(problem.id),
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
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                            fontWeight: FontWeight.bold,
                          ),
                        ),

                        const SizedBox(height: 8),

                        Text(
                          problem.reason,
                          style: const TextStyle(height: 1.4),
                        ),

                        const SizedBox(height: 10),

                        Align(
                          alignment: Alignment.centerLeft,
                          child: TextButton.icon(
                            onPressed: _openingProblem ? null : () => _openProblem(problem.id),
                            icon: const Icon(Icons.play_arrow),
                            label: const Text('이 문제 풀기'),
                          ),
                        ),
                        Wrap(
                          spacing: 8,
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
                ),
              );
            }),
          ],
        );
      },
    );
  }

  /// header: 이 기능의 화면 상태·요청·데이터 처리를 담당합니다.
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
  /// build: 화면 위젯 구조를 구성합니다.
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
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
      body: Column(
        children: [
          if (!widget.isAccepted)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _openingProblem ? null
                      : () => _openProblem(widget.problemId, retry: true),
                  icon: const Icon(Icons.refresh),
                  label: Text(_openingProblem ? '문제를 불러오는 중...' : '다시 풀기'),
                ),
              ),
            ),
          Expanded(
            child: FutureBuilder<AIAnalysis>(
              future: futureAnalysis,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('AI 분석을 불러오지 못했습니다.'),
                    TextButton.icon(
                      onPressed: () => setState(() => futureAnalysis = _loadAnalysis()),
                      icon: const Icon(Icons.refresh), label: const Text('분석 다시 시도'),
                    ),
                  ],
                ));
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
                    ProgressiveHints(
                      key: ValueKey(widget.submissionId),
                      hints: [a.hint1, a.hint2, a.hint3],
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
                    if (widget.isAccepted) recommendationSection(),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}