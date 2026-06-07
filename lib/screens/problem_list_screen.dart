import 'package:flutter/material.dart';
import '../models/problem.dart';
import '../core/problem_api.dart';
import 'problem_detail_screen.dart';
import 'submission_history_screen.dart';
import '../core/auth_api.dart';
import 'login_screen.dart';

class ProblemListScreen extends StatefulWidget {
  final int userId;

  const ProblemListScreen({
    super.key,
    required this.userId,
  });

  @override
  State<ProblemListScreen> createState() => _ProblemListScreenState();
}

class _ProblemListScreenState extends State<ProblemListScreen> {
  late Future<List<Problem>> futureProblems;

  @override
  void initState() {
    super.initState();
    print('PROBLEM LIST USER ID: ${widget.userId}');
    futureProblems = ProblemApi.fetchProblems(widget.userId);
  }

  Color difficultyColor(String difficulty) {
    final value = difficulty.toLowerCase();

    if (value == 'easy') return Colors.green;
    if (value == 'medium') return Colors.orange;
    if (value == 'hard') return Colors.red;

    return Colors.blue;
  }

  String difficultyText(String difficulty) {
    final value = difficulty.toLowerCase();

    if (value == 'easy') return '쉬움';
    if (value == 'medium') return '보통';
    if (value == 'hard') return '어려움';

    return difficulty;
  }

  Future<void> openProblemDetail(BuildContext context, Problem p) async {
    try {
      final detailProblem = await ProblemApi.fetchProblemDetail(p.id);

      if (!context.mounted) return;

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ProblemDetailScreen(
            problem: detailProblem,
            userId: widget.userId,
          ),
        ),
      );
    } catch (e) {
      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('문제 상세 정보를 불러오지 못했습니다: $e'),
        ),
      );
    }
  }

  Widget header(int count) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: const LinearGradient(
          colors: [
            Color(0xFF4F7CFF),
            Color(0xFF6C63FF),
          ],
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.school,
            color: Colors.white,
            size: 38,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              'AI와 함께 코딩 문제를 학습하세요.\n현재 $count개의 문제가 준비되어 있습니다.',
              style: const TextStyle(
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

  Widget problemCard(BuildContext context, Problem p) {
    final color = difficultyColor(p.difficulty);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
      ),
      elevation: 2,
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () => openProblemDetail(context, p),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: color.withOpacity(0.12),
                child: Icon(
                  Icons.code,
                  color: color,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      p.title,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      p.category,
                      style: TextStyle(
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (p.isSolved) ...[
                    const Icon(
                      Icons.check_circle,
                      color: Colors.green,
                      size: 24,
                    ),
                    const SizedBox(width: 8),
                  ],
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
                      difficultyText(p.difficulty),
                      style: TextStyle(
                        color: color,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget errorView(Object? error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text(
          '문제 목록을 불러오지 못했습니다.\n$error',
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  Widget emptyView() {
    return const Center(
      child: Text('등록된 문제가 없습니다.'),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      appBar: AppBar(
        title: const Text('러닝패스'),
        actions: [
          IconButton(
            tooltip: '제출 기록',
            icon: const Icon(Icons.history),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => SubmissionHistoryScreen(userId: widget.userId),
                ),
              );
            },
          ),

          IconButton(
            tooltip: '로그아웃',
            icon: const Icon(Icons.logout),
            onPressed: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (context) {
                  return AlertDialog(
                    title: const Text('로그아웃'),
                    content: const Text('정말 로그아웃하시겠습니까?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text('취소'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(context, true),
                        child: const Text('로그아웃'),
                      ),
                    ],
                  );
                },
              );

              if (confirm != true) return;

              if (!context.mounted) return;

              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(
                  builder: (_) => const LoginScreen(),
                ),
                    (route) => false,
              );
            },
          ),

          IconButton(
            tooltip: '회원탈퇴',
            icon: const Icon(Icons.delete_forever),
            onPressed: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (context) {
                  return AlertDialog(
                    title: const Text('회원탈퇴'),
                    content: const Text(
                      '정말 탈퇴하시겠습니까?\n제출 기록과 AI 분석도 함께 삭제됩니다.',
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text('취소'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(context, true),
                        child: const Text('탈퇴'),
                      ),
                    ],
                  );
                },
              );

              if (confirm != true) return;

              try {
                await AuthApi.deleteUser(widget.userId);

                if (!context.mounted) return;

                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const LoginScreen(),
                  ),
                      (route) => false,
                );
              } catch (e) {
                if (!context.mounted) return;

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(e.toString().replaceAll('Exception: ', '')),
                  ),
                );
              }
            },
          ),
        ],
      ),
      body: FutureBuilder<List<Problem>>(
        future: futureProblems,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (snapshot.hasError) {
            return errorView(snapshot.error);
          }

          final problems = snapshot.data ?? [];

          if (problems.isEmpty) {
            return emptyView();
          }

          return ListView.builder(
            itemCount: problems.length + 1,
            itemBuilder: (context, index) {
              if (index == 0) {
                return header(problems.length);
              }

              final p = problems[index - 1];

              return problemCard(context, p);
            },
          );
        },
      ),
    );
  }
}