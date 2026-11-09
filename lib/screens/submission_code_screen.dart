// 파일 역할: 사용자에게 표시되는 Flutter 화면과 입력·상태 처리: submission code screen
// 주요 선언부에는 담당 기능을 설명하는 한국어 주석을 추가했습니다.
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../core/submission_api.dart';
import '../core/problem_api.dart';
import 'problem_detail_screen.dart';

/// SubmissionCodeScreen: 해당 기능을 표시하는 화면 위젯입니다.
class SubmissionCodeScreen extends StatefulWidget {
  final int userId;
  final int submissionId;
  const SubmissionCodeScreen({super.key, required this.userId, required this.submissionId});
  @override
  /// createState: 이 기능의 화면 상태·요청·데이터 처리를 담당합니다.
  State<SubmissionCodeScreen> createState() => _SubmissionCodeScreenState();
}

/// _SubmissionCodeScreenState: 화면/모델 내부에서만 사용하는 보조 처리입니다.
class _SubmissionCodeScreenState extends State<SubmissionCodeScreen> {
  late Future<Map<String, dynamic>> _submission;
  bool _opening = false;
  @override
  /// initState: 이 기능의 화면 상태·요청·데이터 처리를 담당합니다.
  void initState() {
    super.initState();
    _submission = _load();
  }
  /// _load: 화면/모델 내부에서만 사용하는 보조 처리입니다.
  Future<Map<String, dynamic>> _load() => SubmissionApi.fetchSubmission(
    userId: widget.userId, submissionId: widget.submissionId,
  );
  /// _retryProblem: 화면/모델 내부에서만 사용하는 보조 처리입니다.
  Future<void> _retryProblem(Map<String, dynamic> data) async {
    if (_opening) return;
    setState(() => _opening = true);
    try {
      final problem = await ProblemApi.fetchProblemDetail(data['problem_id']);
      if (!mounted) return;
      await Navigator.push(context, MaterialPageRoute(
        builder: (_) => ProblemDetailScreen(
          problem: problem, userId: widget.userId, initialCode: data['source_code'],
        ),
      ));
    } catch (_) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('문제를 불러오지 못했습니다. 다시 시도해주세요.')),
      );
    } finally {
      if (mounted) setState(() => _opening = false);
    }
  }
  @override
  /// build: 화면 위젯 구조를 구성합니다.
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('제출했던 코드')),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _submission,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError || !snapshot.hasData) {
            return Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
              const Text('제출 코드를 불러오지 못했습니다.'),
              TextButton.icon(
                onPressed: () => setState(() => _submission = _load()),
                icon: const Icon(Icons.refresh), label: const Text('다시 시도'),
              ),
            ]));
          }
          final data = snapshot.data!;
          final code = data['source_code'] as String;
          return Padding(
            padding: const EdgeInsets.all(16),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(data['problem_title'] ?? '', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text('${data['language']} · ${data['verdict']} · ${data['passed_count']}/${data['total_count']} 통과'),
              Text('${data['created_at'] ?? ''}'),
              const SizedBox(height: 12),
              Wrap(spacing: 12, children: [
                OutlinedButton.icon(
                  onPressed: () async {
                    await Clipboard.setData(ClipboardData(text: code));
                    if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('코드를 복사했습니다.')),
                    );
                  },
                  icon: const Icon(Icons.copy), label: const Text('코드 복사'),
                ),
                OutlinedButton.icon(
                  onPressed: _opening ? null : () => _retryProblem(data),
                  icon: const Icon(Icons.refresh), label: const Text('이 코드로 다시 풀기'),
                ),
              ]),
              const SizedBox(height: 12),
              Expanded(child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  border: Border.all(color: Theme.of(context).dividerColor),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: SingleChildScrollView(child: SelectableText(
                  code, style: const TextStyle(fontFamily: 'monospace', height: 1.5),
                )),
              )),
            ]),
          );
        },
      ),
    );
  }
}
