import 'package:flutter/material.dart';
import '../models/problem.dart';
import '../core/submission_api.dart';
import 'submission_result_screen.dart';
import 'problem_list_screen.dart';

class ProblemDetailScreen extends StatefulWidget {
  final Problem problem;
  final int userId;

  const ProblemDetailScreen({
    super.key,
    required this.problem,
    required this.userId,
  });

  @override
  State<ProblemDetailScreen> createState() => _ProblemDetailScreenState();
}

class _ProblemDetailScreenState extends State<ProblemDetailScreen> {
  final TextEditingController codeController = TextEditingController(
    text: 'a, b = map(int, input().split())\nprint(a + b)',
  );

  bool _isAutoIndenting = false;
  bool isSubmitting = false;

  void handleAutoIndent(String value) {
    if (_isAutoIndenting) return;

    final selection = codeController.selection;

    if (!selection.isValid || selection.start <= 0) return;

    final cursorPosition = selection.start;
    final beforeCursor = value.substring(0, cursorPosition);

    if (!beforeCursor.endsWith('\n')) return;

    final previousText = beforeCursor.substring(0, beforeCursor.length - 1);
    final lines = previousText.split('\n');

    if (lines.isEmpty) return;

    final previousLine = lines.last;

    final leadingSpacesMatch = RegExp(r'^\s*').firstMatch(previousLine);
    final currentIndent = leadingSpacesMatch?.group(0) ?? '';

    String nextIndent = currentIndent;

    if (previousLine.trimRight().endsWith(':')) {
      nextIndent += '    ';
    }

    if (nextIndent.isEmpty) return;

    final newText =
        value.substring(0, cursorPosition) +
            nextIndent +
            value.substring(cursorPosition);

    _isAutoIndenting = true;

    codeController.value = TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(
        offset: cursorPosition + nextIndent.length,
      ),
    );

    _isAutoIndenting = false;
  }

  Future<void> submit() async {

    print('DETAIL USER ID: ${widget.userId}');
    setState(() => isSubmitting = true);

    try {
      final result = await SubmissionApi.submitCode(
        userId: widget.userId,
        problemId: widget.problem.id,
        sourceCode: codeController.text,
      );

      if (!mounted) return;

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => SubmissionResultScreen(
            result: result,
            userId: widget.userId,
          ),
        ),
      );
    } catch (e) {
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
  Widget build(BuildContext context) {
    final p = widget.problem;

    return Scaffold(
      appBar: AppBar(
        title: Text(p.title),
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
                          color: Colors.grey.shade100,
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
                          color: Colors.grey.shade100,
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
                maxLines: null,
                expands: true,
                onChanged: handleAutoIndent,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: 'Python 코드 작성',
                ),
              ),
            ),

            const SizedBox(height: 12),

            ElevatedButton(
              onPressed: isSubmitting ? null : submit,
              child: isSubmitting
                  ? const CircularProgressIndicator()
                  : const Text('제출하기'),
            ),
          ],
        ),
      ),
    );
  }
}