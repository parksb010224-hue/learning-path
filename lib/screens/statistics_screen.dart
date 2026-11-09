// 파일 역할: 사용자에게 표시되는 Flutter 화면과 입력·상태 처리: statistics screen
// 주요 선언부에는 담당 기능을 설명하는 한국어 주석을 추가했습니다.
import 'package:flutter/material.dart';
import '../core/submission_history_api.dart';
import '../core/problem_api.dart';
import '../models/learning_statistics.dart';
import '../models/problem.dart';
import '../models/submission_history.dart';
import 'problem_list_screen.dart';

/// StatisticsScreen: 해당 기능을 표시하는 화면 위젯입니다.
class StatisticsScreen extends StatefulWidget {
  final int userId;
  const StatisticsScreen({super.key, required this.userId});
  @override
  /// createState: 이 기능의 화면 상태·요청·데이터 처리를 담당합니다.
  State<StatisticsScreen> createState() => _StatisticsScreenState();
}

/// _StatisticsScreenState: 화면/모델 내부에서만 사용하는 보조 처리입니다.
class _StatisticsScreenState extends State<StatisticsScreen> {
  late Future<LearningStatistics> _statistics;
  @override
  /// initState: 이 기능의 화면 상태·요청·데이터 처리를 담당합니다.
  void initState() {
    super.initState();
    _statistics = _load();
  }
  /// _load: 화면/모델 내부에서만 사용하는 보조 처리입니다.
  Future<LearningStatistics> _load() async {
    final data = await Future.wait<dynamic>([
      SubmissionHistoryApi.fetchSubmissions(userId: widget.userId),
      ProblemApi.fetchProblems(widget.userId),
    ]);
    return LearningStatistics.fromData(
      data[0] as List<SubmissionHistory>, data[1] as List<Problem>,
    );
  }
  /// _refresh: 화면/모델 내부에서만 사용하는 보조 처리입니다.
  Future<void> _refresh() async {
    final future = _load();
    setState(() => _statistics = future);
    try { await future; } catch (_) { /* FutureBuilder displays the error. */ }
  }
  /// _summaryCard: 화면/모델 내부에서만 사용하는 보조 처리입니다.
  Widget _summaryCard(String title, String value, IconData icon, Color color) {
    return Card(child: ListTile(
      leading: CircleAvatar(backgroundColor: color.withOpacity(0.12), child: Icon(icon, color: color)),
      title: Text(title),
      trailing: Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
    ));
  }
  /// _categoryCard: 화면/모델 내부에서만 사용하는 보조 처리입니다.
  Widget _categoryCard(CategoryLearningStatistics data) {
    final percent = (data.acceptanceRate * 100).toStringAsFixed(1);
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(data.category, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          Text(data.submissions == 0 ? '아직 제출한 기록이 없습니다.' : '제출 정답률 $percent%'),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: data.acceptanceRate,
            minHeight: 8,
            color: data.submissions == 0 ? Colors.grey : Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(height: 12),
          Wrap(spacing: 16, runSpacing: 8, children: [
            Text('제출 ${data.submissions}회'),
            Text('정답 ${data.accepted}회'),
            Text('오답·오류 ${data.failed}회'),
            Text('시도 ${data.attemptedProblems}문제'),
            Text('해결 ${data.solvedProblems}문제'),
            Text('미해결 ${data.unresolvedProblems}문제'),
          ]),
        ]),
      ),
    );
  }
  @override
  /// build: 화면 위젯 구조를 구성합니다.
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('학습 통계'), actions: [
        IconButton(tooltip: '새로고침', icon: const Icon(Icons.refresh), onPressed: _refresh),
        IconButton(tooltip: '문제 목록', icon: const Icon(Icons.home), onPressed: () {
          Navigator.pushAndRemoveUntil(context, MaterialPageRoute(
            builder: (_) => ProblemListScreen(userId: widget.userId),
          ), (route) => false);
        }),
      ]),
      body: FutureBuilder<LearningStatistics>(
        future: _statistics,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError || !snapshot.hasData) {
            return Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
              const Text('학습 통계를 불러오지 못했습니다.'),
              TextButton.icon(onPressed: _refresh, icon: const Icon(Icons.refresh), label: const Text('다시 시도')),
            ]));
          }
          final data = snapshot.data!;
          return RefreshIndicator(
            onRefresh: _refresh,
            child: ListView(
              padding: const EdgeInsets.all(16),
              physics: const AlwaysScrollableScrollPhysics(),
              children: [
                const Text('나의 학습 현황', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                _summaryCard('총 제출 수', '${data.submissions}회', Icons.upload_file, Colors.blue),
                _summaryCard('정답 제출', '${data.accepted}회', Icons.check_circle, Colors.green),
                _summaryCard('오답·오류 제출', '${data.failed}회', Icons.cancel, Colors.red),
                _summaryCard('제출 정답률', '${(data.acceptanceRate * 100).toStringAsFixed(1)}%', Icons.percent, Colors.purple),
                _summaryCard('해결 / 시도 문제', '${data.solvedProblems} / ${data.attemptedProblems}', Icons.school, Colors.teal),
                if (data.submissions == 0) const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Text('아직 제출한 기록이 없습니다. 문제를 풀면 유형별 학습 현황이 쌓입니다.'),
                ),
                const SizedBox(height: 24),
                const Text('유형별 학습 통계', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                const Text('정답률은 전체 제출 중 정답 제출의 비율입니다.\n시도·해결 문제 수는 같은 문제를 중복으로 세지 않습니다.\n미해결은 시도했지만 아직 정답을 받지 못한 문제입니다.'),
                const SizedBox(height: 16),
                if (data.categories.isEmpty) const Text('등록된 문제 유형이 없습니다.'),
                ...data.categories.map(_categoryCard),
              ],
            ),
          );
        },
      ),
    );
  }
}
