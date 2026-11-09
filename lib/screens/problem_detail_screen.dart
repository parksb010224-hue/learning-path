// 파일 역할: 문제 설명·코드 작성·예제 실행·제출 진입 화면
// 주요 선언부에는 담당 기능을 설명하는 한국어 주석을 추가했습니다.
import 'submission_progress_screen.dart';
import '../models/submission_response.dart';
import 'dart:async';
import 'package:flutter/material.dart';
import '../models/problem.dart';
import '../models/example_run_result.dart';
import '../utils/python_input_template.dart';
import '../utils/python_code_input_formatter.dart';
import '../core/submission_api.dart';
import '../core/code_draft_store.dart';
import 'submission_result_screen.dart';
import 'problem_list_screen.dart';

/// ProblemDetailScreen: 해당 기능을 표시하는 화면 위젯입니다.
class ProblemDetailScreen extends StatefulWidget {
  final Problem problem;
  final int userId;
  final String? initialCode;

  const ProblemDetailScreen({
    super.key,
    required this.problem,
    required this.userId,
    this.initialCode,
  });

  @override
  /// createState: 이 기능의 화면 상태·요청·데이터 처리를 담당합니다.
  State<ProblemDetailScreen> createState() => _ProblemDetailScreenState();
}

/// _ProblemDetailScreenState: 화면/모델 내부에서만 사용하는 보조 처리입니다.
class _ProblemDetailScreenState extends State<ProblemDetailScreen>
    with WidgetsBindingObserver {
  late final TextEditingController codeController;
  Timer? _saveTimer;
  bool _loadingDraft = true;
  bool _restoringDraft = false;
  bool _allowPop = false;
  bool _leaving = false;
  String? _lastSavedCode;
  String? _observedCode;
  String? _lastQueuedCode;
  Future<void>? _pendingSave;
  String _saveStatus = '임시 저장 코드를 불러오는 중...';

  @override
  /// initState: 이 기능의 화면 상태·요청·데이터 처리를 담당합니다.
  void initState() {
    super.initState();
    codeController = TextEditingController(
      text: widget.initialCode ?? buildPythonInputTemplate(widget.problem),
    );
    WidgetsBinding.instance.addObserver(this);
    codeController.addListener(_onCodeChanged);
    unawaited(_loadDraft(useInitialCode: true));
  }

  /// _loadDraft: 화면/모델 내부에서만 사용하는 보조 처리입니다.
  Future<void> _loadDraft({bool useInitialCode = false}) async {
    if (mounted) setState(() => _loadingDraft = true);
    try {
      final saved = useInitialCode && widget.initialCode != null
          ? widget.initialCode
          : await CodeDraftStore.instance.readDraft(widget.userId, widget.problem.id);
      if (!mounted) return;
      _restoringDraft = true;
      if (saved != null) {
        codeController.value = TextEditingValue(
          text: saved,
          selection: TextSelection.collapsed(offset: saved.length),
        );
      }
      _lastSavedCode = saved ?? codeController.text;
      _lastQueuedCode = _lastSavedCode;
      _observedCode = codeController.text;
      _restoringDraft = false;
      setState(() {
        _loadingDraft = false;
        _saveStatus = saved == null ? '작성한 코드는 자동으로 저장됩니다.' : '저장된 코드를 불러왔습니다.';
      });
      if (useInitialCode && widget.initialCode != null) {
        _lastSavedCode = null;
        _lastQueuedCode = null;
        await _saveDraft();
      }
    } catch (_) {
      if (!mounted) return;
      _restoringDraft = false;
      // Do not overwrite an unread draft with the default starter on exit.
      _lastSavedCode = codeController.text;
      _lastQueuedCode = codeController.text;
      _observedCode = codeController.text;
      setState(() {
        _loadingDraft = false;
        _saveStatus = '임시 저장 코드를 불러오지 못했습니다.';
      });
    }
  }

  /// _onCodeChanged: 화면/모델 내부에서만 사용하는 보조 처리입니다.
  void _onCodeChanged() {
    if (_loadingDraft || _restoringDraft || codeController.text == _observedCode) return;
    _observedCode = codeController.text;
    _saveTimer?.cancel();
    if (mounted) setState(() => _saveStatus = '저장 중...');
    _saveTimer = Timer(const Duration(milliseconds: 300), () {
      unawaited(_saveDraft());
    });
  }

  /// _saveDraft: 화면/모델 내부에서만 사용하는 보조 처리입니다.
  Future<bool> _saveDraft() async {
    _saveTimer?.cancel();
    if (_loadingDraft) return true;
    final code = codeController.text;
    try {
      if (code == _lastSavedCode && code == _lastQueuedCode) {
        if (_pendingSave != null) await _pendingSave;
        return true;
      }
      _lastQueuedCode = code;
      final operation = CodeDraftStore.instance.saveDraft(widget.userId, widget.problem.id, code);
      _pendingSave = operation;
      await operation;
      _lastSavedCode = code;
      if (mounted && codeController.text == code) {
        setState(() => _saveStatus = '임시 저장됨');
      }
      return true;
    } catch (_) {
      _lastQueuedCode = null;
      _pendingSave = null;
      if (mounted) setState(() => _saveStatus = '임시 저장 실패 · 저장 버튼을 눌러 재시도하세요.');
      return false;
    }
  }

  /// _leave: 화면/모델 내부에서만 사용하는 보조 처리입니다.
  Future<void> _leave({bool goHome = false}) async {
    if (_leaving || _loadingDraft) return;
    _leaving = true;
    if (!await _saveDraft()) {
      _leaving = false;
      return;
    }
    if (!mounted) return;
    if (goHome) {
      Navigator.pushAndRemoveUntil(context,
        MaterialPageRoute(builder: (_) => ProblemListScreen(userId: widget.userId)),
        (route) => false,
      );
    } else {
      setState(() => _allowPop = true);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) Navigator.pop(context);
      });
    }
  }

  @override
  /// didChangeAppLifecycleState: 이 기능의 화면 상태·요청·데이터 처리를 담당합니다.
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) unawaited(_saveDraft());
  }

  @override
  /// dispose: 이 기능의 화면 상태·요청·데이터 처리를 담당합니다.
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _saveTimer?.cancel();
    codeController.removeListener(_onCodeChanged);
    // Capture pending edits before disposing the controller.
    unawaited(_saveDraft());
    codeController.dispose();
    super.dispose();
  }

  bool isSubmitting = false;
  bool _runningExamples = false;

  /// _runExamples: 화면/모델 내부에서만 사용하는 보조 처리입니다.
  Future<void> _runExamples() async {
    if (_runningExamples || isSubmitting || _loadingDraft) return;
    if (codeController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('실행할 코드를 작성해주세요.')),
      );
      return;
    }
    setState(() => _runningExamples = true);
    final code = codeController.text;
    try {
      await _saveDraft();
      final result = await SubmissionApi.runExamples(
        problemId: widget.problem.id, sourceCode: code,
      );
      if (!mounted) return;
      // Execution is complete. A modal result panel is not a running job.
      setState(() => _runningExamples = false);
      final shouldSubmit = await showModalBottomSheet<bool>(
        context: context,
        isScrollControlled: true,
        builder: (context) => SafeArea(child: SizedBox(
          height: MediaQuery.of(context).size.height * 0.75,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                const Expanded(child: Text('예제 실행 결과', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold))),
                IconButton(
                  tooltip: '닫기',
                  onPressed: () => Navigator.pop(context, false),
                  icon: const Icon(Icons.close),
                ),
              ]),
              Text('${result.passedCount}/${result.totalCount} 통과 · 제출 기록에는 저장되지 않습니다.'),
              const SizedBox(height: 12),
              Expanded(child: ListView(children: result.cases.map(_exampleCard).toList())),
              const SizedBox(height: 12),
              Row(children: [
                Expanded(child: OutlinedButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('닫고 수정하기'),
                )),
                const SizedBox(width: 12),
                Expanded(child: ElevatedButton.icon(
                  onPressed: () => Navigator.pop(context, true),
                  icon: const Icon(Icons.send),
                  label: const Text('코드 제출'),
                )),
              ]),
            ]),
          ),
        )),
      );
      // Close the modal before opening the normal submission-result screen.
      if (shouldSubmit == true && mounted) await submit();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('예제 실행 실패: ${e.toString().replaceFirst('Exception: ', '')}'),
      ));
    } finally {
      if (mounted) setState(() => _runningExamples = false);
    }
  }

  /// _exampleCard: 화면/모델 내부에서만 사용하는 보조 처리입니다.
  Widget _exampleCard(ExampleRunCase example) {
    const labels = {
      'ACCEPTED': '일치', 'WRONG_ANSWER': '불일치',
      'RUNTIME_ERROR': '실행 오류', 'TIME_LIMIT_EXCEEDED': '시간 초과',
    };
    return Card(child: Padding(
      padding: const EdgeInsets.all(12),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('예제 ${example.number}: ${labels[example.result] ?? example.result}',
          style: TextStyle(fontWeight: FontWeight.bold,
            color: example.result == 'ACCEPTED' ? Colors.green : Colors.red)),
        const SizedBox(height: 8),
        const Text('입력'),
        SelectableText(example.input, style: const TextStyle(fontFamily: 'monospace')),
        const SizedBox(height: 8),
        const Text('예상 출력'),
        SelectableText(example.expected, style: const TextStyle(fontFamily: 'monospace')),
        const SizedBox(height: 8),
        const Text('내 출력'),
        SelectableText(example.actual.isEmpty ? '(출력 없음)' : example.actual,
          style: const TextStyle(fontFamily: 'monospace')),
        if (example.stderr.isNotEmpty) ...[
          const SizedBox(height: 8), const Text('오류 / 메시지'),
          SelectableText(example.stderr, style: const TextStyle(fontFamily: 'monospace')),
        ],
      ]),
    ));
  }

  /// submit: 이 기능의 화면 상태·요청·데이터 처리를 담당합니다.
  Future<void> submit() async {
    if (isSubmitting || _runningExamples || _loadingDraft) return;
    if (codeController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('제출할 코드를 작성해주세요.')),
      );
      return;
    }

    print('DETAIL USER ID: ${widget.userId}');
    setState(() => isSubmitting = true);

    try {
      await _saveDraft();
      final submittedCode = codeController.text;
      if (!mounted) return;
      final result = await Navigator.push<SubmissionResponse>(
        context,
        MaterialPageRoute(builder: (_) => SubmissionProgressScreen(
          userId: widget.userId, problemId: widget.problem.id,
          problemTitle: widget.problem.title, sourceCode: submittedCode,
        )),
      );

      if (!mounted || result == null) return;

      try {
        await CodeDraftStore.instance.saveSubmission(
          widget.userId, result.submissionId, submittedCode,
        );
      } catch (_) {
        // The current result still carries the code if local saving fails.
      }
      if (!mounted) return;
      setState(() => isSubmitting = false);
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => SubmissionResultScreen(
            result: result,
            userId: widget.userId,
            problem: widget.problem,
            submittedCode: submittedCode,
          ),
        ),
      );
      if (mounted) await _loadDraft();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('제출 실패: $e'),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => isSubmitting = false);
      }
    }
  }

  @override
  /// build: 화면 위젯 구조를 구성합니다.
  Widget build(BuildContext context) {
    final p = widget.problem;

    return PopScope(
      canPop: _allowPop,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) unawaited(_leave());
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(p.title),
          actions: [
            IconButton(
              tooltip: '문제 목록',
              icon: const Icon(Icons.home),
              onPressed: _loadingDraft ? null : () => _leave(goHome: true),
            ),
          ],
        ),
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        p.description,
                        style: const TextStyle(fontSize: 16),
                      ),

                      const SizedBox(height: 24),

                      const Text(
                        '입력',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      const SizedBox(height: 8),

                      Text(
                        p.inputDesc ?? '입력 형식이 없습니다.',
                        style: const TextStyle(fontSize: 15),
                      ),

                      const SizedBox(height: 20),

                      const Text(
                        '출력',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      const SizedBox(height: 8),

                      Text(
                        p.outputDesc ?? '출력 형식이 없습니다.',
                        style: const TextStyle(fontSize: 15),
                      ),

                      const SizedBox(height: 24),

                      for (int i = 0; i < p.examples.length; i++) ...[
                        Text(
                          '예제 입력 ${i + 1}',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),

                        const SizedBox(height: 8),

                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            p.examples[i].inputData,
                            style: const TextStyle(fontFamily: 'monospace'),
                          ),
                        ),

                        const SizedBox(height: 12),

                        Text(
                          '예제 출력 ${i + 1}',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),

                        const SizedBox(height: 8),

                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            p.examples[i].expectedOutput,
                            style: const TextStyle(fontFamily: 'monospace'),
                          ),
                        ),

                        const SizedBox(height: 20),
                      ],

                      if (p.examples.isEmpty)
                        const Text('예제 입출력이 없습니다.'),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 12),

              Expanded(
                child: TextField(
                  controller: codeController,
                  enabled: !_loadingDraft && !isSubmitting && !_runningExamples,
                  maxLines: null,
                  expands: true,
                  inputFormatters: const [PythonCodeInputFormatter()],
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    labelText: 'Python 코드 작성',
                  ),
                ),
              ),

              const SizedBox(height: 12),

              Row(
                children: [
                  Expanded(child: Text(_saveStatus, style: const TextStyle(fontSize: 12))),
                  TextButton.icon(
                    onPressed: _loadingDraft ? null : () { unawaited(_saveDraft()); },
                    icon: const Icon(Icons.save_outlined),
                    label: const Text('저장'),
                  ),
                ],
              ),
              Wrap(
                spacing: 12,
                alignment: WrapAlignment.center,
                children: [
                  OutlinedButton.icon(
                    onPressed: _runningExamples || isSubmitting || _loadingDraft || widget.problem.examples.isEmpty
                        ? null : _runExamples,
                    icon: _runningExamples
                        ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                        : const Icon(Icons.play_arrow),
                    label: Text(_runningExamples ? '예제 실행 중...' : '예제 실행'),
                  ),
                  ElevatedButton(
                    onPressed: isSubmitting || _runningExamples || _loadingDraft ? null : submit,
                    child: isSubmitting
                        ? const CircularProgressIndicator()
                        : const Text('제출하기'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
