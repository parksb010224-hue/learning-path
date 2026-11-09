// 파일 역할: 사용자에게 표시되는 Flutter 화면과 입력·상태 처리: submission progress screen
// 주요 선언부에는 담당 기능을 설명하는 한국어 주석을 추가했습니다.
import 'dart:math';
import 'package:flutter/material.dart';
import '../core/submission_api.dart';
import '../models/submission_progress.dart';
import '../models/submission_response.dart';

typedef StartProgress = Future<SubmissionProgress> Function(String requestKey);
typedef LoadProgress = Future<SubmissionProgress> Function(String jobId);

/// SubmissionProgressScreen: 해당 기능을 표시하는 화면 위젯입니다.
class SubmissionProgressScreen extends StatefulWidget {
  final int userId;
  final int problemId;
  final String sourceCode;
  final String problemTitle;
  // Injectable transport for widget tests; production uses SubmissionApi.
  final StartProgress? startJob;
  final LoadProgress? loadJob;
  const SubmissionProgressScreen({super.key, required this.userId,
    required this.problemId, required this.sourceCode, required this.problemTitle,
    this.startJob, this.loadJob});
  @override
  /// createState: 이 기능의 화면 상태·요청·데이터 처리를 담당합니다.
  State<SubmissionProgressScreen> createState() => _SubmissionProgressScreenState();
}

/// _SubmissionProgressScreenState: 화면/모델 내부에서만 사용하는 보조 처리입니다.
class _SubmissionProgressScreenState extends State<SubmissionProgressScreen> {
  late final String _requestKey;
  SubmissionProgress? _progress;
  String? _connectionError;
  bool _working = true;

  @override
  /// initState: 이 기능의 화면 상태·요청·데이터 처리를 담당합니다.
  void initState() {
    super.initState();
    final random = Random.secure();
    _requestKey = List.generate(4, (_) => random.nextInt(0x100000000)
      .toRadixString(16).padLeft(8, '0')).join();
    _start();
  }

  /// _start: 화면/모델 내부에서만 사용하는 보조 처리입니다.
  Future<void> _start() async {
    setState(() { _working = true; _connectionError = null; });
    try {
      final job = await (widget.startJob?.call(_requestKey) ?? SubmissionApi.startSubmission(
        userId: widget.userId, problemId: widget.problemId,
        sourceCode: widget.sourceCode, requestKey: _requestKey));
      if (!mounted) return;
      setState(() => _progress = job);
      await _poll();
    } catch (e) { _showConnectionError(e); }
  }

  /// _showConnectionError: 화면/모델 내부에서만 사용하는 보조 처리입니다.
  void _showConnectionError(Object error) {
    if (!mounted) return;
    setState(() {
      _working = false;
      _connectionError = error.toString().replaceFirst('Exception: ', '');
    });
  }

  /// _poll: 화면/모델 내부에서만 사용하는 보조 처리입니다.
  Future<void> _poll() async {
    try {
      while (mounted) {
        final job = _progress!;
        if (job.completed || job.failed) {
          if (job.completed && job.result == null) throw Exception('완료 결과를 읽지 못했습니다. 상태를 다시 조회해주세요.');
          setState(() => _working = false);
          return;
        }
        // Sequential requests: never overlap status reads or resend the code.
        await Future<void>.delayed(const Duration(milliseconds: 700));
        if (!mounted) return;
        final next = await (widget.loadJob?.call(job.jobId) ?? SubmissionApi.fetchProgress(
          jobId: job.jobId, userId: widget.userId));
        if (!mounted) return;
        setState(() => _progress = next);
      }
    } catch (e) { _showConnectionError(e); }
  }

  /// _resume: 화면/모델 내부에서만 사용하는 보조 처리입니다.
  Future<void> _resume() async {
    setState(() { _working = true; _connectionError = null; });
    if (_progress == null) {
      // Same idempotency key recovers an accepted request whose response was lost.
      await _start();
    } else {
      // Always reload once, including when the previous completion was malformed.
      try {
        final next = await (widget.loadJob?.call(_progress!.jobId) ?? SubmissionApi.fetchProgress(
          jobId: _progress!.jobId, userId: widget.userId));
        if (!mounted) return;
        setState(() => _progress = next);
        await _poll();
      } catch (e) { _showConnectionError(e); }
    }
  }

  @override
  /// build: 화면 위젯 구조를 구성합니다.
  Widget build(BuildContext context) {
    final job = _progress;
    final completed = job?.completed == true && job?.result != null;
    final title = completed ? '채점 완료' : job?.failed == true ? '채점 중단'
      : _connectionError != null ? '진행 상태 확인 필요'
      : job?.status == 'SAVING' ? '결과 저장 중'
      : job?.status == 'RUNNING' ? '채점 중' : '채점 접수 · 대기 중';
    return PopScope(
      canPop: !_working,
      child: Scaffold(
        appBar: AppBar(title: Text(title), automaticallyImplyLeading: !_working),
        body: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(widget.problemTitle, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
            Text(job == null || job.totalCount == 0 ? '테스트케이스 준비 중'
              : '채점 완료 ${job.completedCount} / ${job.totalCount}',
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            LinearProgressIndicator(value: job == null || job.totalCount == 0 ? null
              : job.completedCount / job.totalCount),
            const SizedBox(height: 10),
            Text('정답 ${job?.passedCount ?? 0}개'),
            if (job?.status == 'SAVING')
              const Text('모든 테스트를 확인했습니다. 제출 결과를 저장하고 있습니다.'),
            if (_connectionError != null) ...[
              const SizedBox(height: 12),
              Text(_connectionError!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
              const Text('서버의 채점은 계속될 수 있습니다. 다시 조회해도 중복 제출하지 않습니다.'),
              TextButton.icon(onPressed: _working ? null : _resume,
                icon: const Icon(Icons.refresh),
                label: Text(job == null ? '접수 다시 확인' : '진행 상태 다시 조회')),
            ],
            if (job?.failed == true) ...[
              const SizedBox(height: 12),
              Text(job!.error ?? '채점 중 오류가 발생했습니다.',
                style: TextStyle(color: Theme.of(context).colorScheme.error)),
              const Text('완료된 제출 이력을 확인한 뒤, 문제 화면에서 다시 시도해주세요.'),
            ],
            const SizedBox(height: 12),
            Expanded(child: job == null || job.cases.isEmpty
              ? const Center(child: Text('채점 순서를 기다리고 있습니다.'))
              : ListView.builder(itemCount: job.cases.length, itemBuilder: (context, index) {
                  final item = job.cases[index];
                  final pending = item.result == 'PENDING';
                  final running = item.result == 'RUNNING';
                  final color = item.result == 'ACCEPTED' ? Colors.green
                    : pending || running ? Colors.blueGrey : Colors.red;
                  return ListTile(
                    leading: running
                      ? const SizedBox(width: 22, height: 22,
                          child: CircularProgressIndicator(strokeWidth: 2))
                      : Icon(pending ? Icons.hourglass_empty
                          : item.result == 'ACCEPTED' ? Icons.check_circle : Icons.error_outline,
                          color: color),
                    title: Text('테스트 ${item.number}/${job.totalCount} — ${progressResultLabel(item.result)}'),
                    subtitle: Text(item.isSample ? '공개 예제' : '비공개 테스트'),
                  );
                })),
            const Text('비공개 테스트의 입력과 출력은 표시하지 않습니다.'),
            const SizedBox(height: 12),
            if (completed)
              SizedBox(width: double.infinity, child: FilledButton(
                onPressed: () => Navigator.pop<SubmissionResponse>(context, job!.result),
                child: const Text('제출 결과 보기')))
            else if (!_working)
              SizedBox(width: double.infinity, child: OutlinedButton(
                onPressed: () => Navigator.pop(context), child: const Text('문제로 돌아가기'))),
          ]),
        ),
      ),
    );
  }
}
