// 파일 역할: 사용자에게 표시되는 Flutter 화면과 입력·상태 처리: review list screen
// 주요 선언부에는 담당 기능을 설명하는 한국어 주석을 추가했습니다.
import 'package:flutter/material.dart';
import '../core/problem_api.dart';
import '../core/submission_history_api.dart';
import '../core/submission_api.dart';
import '../core/code_draft_store.dart';
import '../models/problem.dart';
import '../models/submission_history.dart';
import '../models/review_problem.dart';
import '../utils/problem_filters.dart';
import 'problem_detail_screen.dart';
import 'submission_code_screen.dart';

/// ReviewListScreen: 해당 기능을 표시하는 화면 위젯입니다.
class ReviewListScreen extends StatefulWidget {
  final int userId;
  const ReviewListScreen({super.key, required this.userId});
  @override
  /// createState: 이 기능의 화면 상태·요청·데이터 처리를 담당합니다.
  State<ReviewListScreen> createState() => _ReviewListScreenState();
}
/// _ReviewListScreenState: 화면/모델 내부에서만 사용하는 보조 처리입니다.
class _ReviewListScreenState extends State<ReviewListScreen> {
  late Future<List<ReviewProblem>> _reviews;
  bool _opening = false;
  @override
  /// initState: 이 기능의 화면 상태·요청·데이터 처리를 담당합니다.
  void initState() {
    super.initState();
    _reviews = _load();
  }
  /// _load: 화면/모델 내부에서만 사용하는 보조 처리입니다.
  Future<List<ReviewProblem>> _load() async {
    final data = await Future.wait<dynamic>([
      SubmissionHistoryApi.fetchSubmissions(userId: widget.userId),
      ProblemApi.fetchProblems(widget.userId),
    ]);
    return buildReviewProblems(data[0] as List<SubmissionHistory>, data[1] as List<Problem>);
  }
  /// _refresh: 화면/모델 내부에서만 사용하는 보조 처리입니다.
  Future<void> _refresh() async {
    final future = _load();
    setState(() => _reviews = future);
    try { await future; } catch (_) { /* Displayed by FutureBuilder. */ }
  }
  /// _retry: 화면/모델 내부에서만 사용하는 보조 처리입니다.
  Future<void> _retry(ReviewProblem item) async {
    if (_opening) return;
    setState(() => _opening = true);
    try {
      final problem = await ProblemApi.fetchProblemDetail(item.problemId);
      // Keep newer unfinished work ahead of the last submitted code.
      String? code;
      try {
        code = await CodeDraftStore.instance.readDraft(widget.userId, item.problemId);
      } catch (_) { /* Try the server snapshot below. */ }
      code ??= item.latestSubmission.sourceCode;
      if (code == null) {
        try {
          final row = await SubmissionApi.fetchSubmission(
            userId: widget.userId, submissionId: item.latestSubmission.id,
          );
          code = row['source_code'] as String?;
        } catch (_) {
          try {
            code = await CodeDraftStore.instance.readSubmission(widget.userId, item.latestSubmission.id);
          } catch (_) { /* The problem's input template remains usable. */ }
        }
      }
      if (!mounted) return;
      await Navigator.push(context, MaterialPageRoute(builder: (_) => ProblemDetailScreen(
        problem: problem, userId: widget.userId, initialCode: code,
      )));
      if (mounted) await _refresh();
    } catch (_) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('문제를 불러오지 못했습니다. 다시 시도해주세요.')),
      );
    } finally {
      if (mounted) setState(() => _opening = false);
    }
  }
  /// _verdict: 화면/모델 내부에서만 사용하는 보조 처리입니다.
  String _verdict(String value) => const {
    'WRONG_ANSWER': '오답', 'RUNTIME_ERROR': '실행 오류',
    'TIME_LIMIT_EXCEEDED': '시간 초과', 'TIME_LIMIT': '시간 초과',
  }[value] ?? value;
  /// _difficulty: 화면/모델 내부에서만 사용하는 보조 처리입니다.
  String _difficulty(String value) => const {
    'easy': '쉬움', 'medium': '보통', 'hard': '어려움',
  }[normalizeDifficulty(value)] ?? value;
  @override
  /// build: 화면 위젯 구조를 구성합니다.
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('오답 복습 목록'), actions: [
      IconButton(tooltip: '새로고침', onPressed: _refresh, icon: const Icon(Icons.refresh)),
    ]),
    body: FutureBuilder<List<ReviewProblem>>(
      future: _reviews,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError || !snapshot.hasData) {
          return Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Text('복습 목록을 불러오지 못했습니다.'),
            TextButton.icon(onPressed: _refresh, icon: const Icon(Icons.refresh), label: const Text('다시 시도')),
          ]));
        }
        final items = snapshot.data!;
        return RefreshIndicator(
          onRefresh: _refresh,
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            physics: const AlwaysScrollableScrollPhysics(),
            itemCount: items.isEmpty ? 2 : items.length + 1,
            itemBuilder: (context, index) {
              if (index == 0) return Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Text('복습할 문제 ${items.length}개 · 최근 제출 순\n한 번이라도 정답을 받은 문제는 제외합니다.'),
              );
              if (items.isEmpty) return const Padding(
                padding: EdgeInsets.all(24),
                child: Center(child: Text('복습할 오답 문제가 없습니다.')),
              );
              final item = items[index - 1];
              return Card(child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(item.title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text('${item.category}${item.difficulty.isEmpty ? '' : ' · ${_difficulty(item.difficulty)}'}'),
                  Text('실패 ${item.failureCount}회 · 최근 결과: ${_verdict(item.latestSubmission.verdict)}'),
                  Text('최근 제출: ${item.latestSubmission.createdAt}'),
                  const SizedBox(height: 12),
                  Wrap(spacing: 12, runSpacing: 8, children: [
                    OutlinedButton.icon(
                      onPressed: () => Navigator.push(context, MaterialPageRoute(
                        builder: (_) => SubmissionCodeScreen(userId: widget.userId,
                          submissionId: item.latestSubmission.id),
                      )),
                      icon: const Icon(Icons.code), label: const Text('최근 제출 코드'),
                    ),
                    ElevatedButton.icon(
                      onPressed: _opening ? null : () => _retry(item),
                      icon: const Icon(Icons.refresh), label: const Text('다시 풀기'),
                    ),
                  ]),
                ]),
              ));
            },
          ),
        );
      },
    ),
  );
}
