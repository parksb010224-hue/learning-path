// 파일 역할: 문제 목록 검색·필터·학습 상태 표시 화면
// 주요 선언부에는 담당 기능을 설명하는 한국어 주석을 추가했습니다.
import 'settings_screen.dart';
import 'package:flutter/material.dart';
import '../models/problem.dart';
import '../utils/problem_filters.dart';
import '../core/problem_api.dart';
import 'problem_detail_screen.dart';
import 'submission_history_screen.dart';
import 'statistics_screen.dart';
import 'review_list_screen.dart';
import '../core/auth_api.dart';
import 'login_screen.dart';

/// ProblemListScreen: 해당 기능을 표시하는 화면 위젯입니다.
class ProblemListScreen extends StatefulWidget {
  final int userId;

  const ProblemListScreen({
    super.key,
    required this.userId,
  });

  @override
  /// createState: 이 기능의 화면 상태·요청·데이터 처리를 담당합니다.
  State<ProblemListScreen> createState() => _ProblemListScreenState();
}

/// _ProblemListScreenState: 화면/모델 내부에서만 사용하는 보조 처리입니다.
class _ProblemListScreenState extends State<ProblemListScreen> {
  late Future<List<Problem>> futureProblems;
  DifficultyFilter selectedDifficulty = DifficultyFilter.all;
  SolvedFilter selectedSolved = SolvedFilter.all;
  String? selectedCategory;
  final searchController = TextEditingController();

  @override
  /// dispose: 이 기능의 화면 상태·요청·데이터 처리를 담당합니다.
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  @override
  /// initState: 이 기능의 화면 상태·요청·데이터 처리를 담당합니다.
  void initState() {
    super.initState();
    print('PROBLEM LIST USER ID: ${widget.userId}');
    futureProblems = ProblemApi.fetchProblems(widget.userId);
  }

  /// difficultyColor: 이 기능의 화면 상태·요청·데이터 처리를 담당합니다.
  Color difficultyColor(String difficulty) {
    final value = normalizeDifficulty(difficulty);

    if (value == 'easy') return Colors.green;
    if (value == 'medium') return Colors.orange;
    if (value == 'hard') return Colors.red;

    return Colors.blue;
  }

  /// difficultyText: 이 기능의 화면 상태·요청·데이터 처리를 담당합니다.
  String difficultyText(String difficulty) {
    final value = normalizeDifficulty(difficulty);

    if (value == 'easy') return '쉬움';
    if (value == 'medium') return '보통';
    if (value == 'hard') return '어려움';

    return difficulty;
  }

  /// openProblemDetail: 이 기능의 화면 상태·요청·데이터 처리를 담당합니다.
  Future<void> openProblemDetail(BuildContext context, Problem p) async {
    try {
      final detailProblem = await ProblemApi.fetchProblemDetail(p.id);

      if (!context.mounted) return;

      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ProblemDetailScreen(
            problem: detailProblem,
            userId: widget.userId,
          ),
        ),
      );
      if (!mounted) return;
      setState(() {
        futureProblems = ProblemApi.fetchProblems(widget.userId);
      });
    } catch (e) {
      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('문제 상세 정보를 불러오지 못했습니다: $e'),
        ),
      );
    }
  }

  /// header: 이 기능의 화면 상태·요청·데이터 처리를 담당합니다.
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

  /// filterControls: 이 기능의 화면 상태·요청·데이터 처리를 담당합니다.
  Widget filterControls(List<Problem> problems) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth < 420
              ? constraints.maxWidth
              : (constraints.maxWidth - 12) / 2;
          return Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              SizedBox(
                width: constraints.maxWidth,
                child: TextField(
                  controller: searchController,
                  decoration: InputDecoration(
                    labelText: '문제 검색',
                    hintText: '문제 제목 또는 유형 검색',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: searchController.text.isEmpty ? null : IconButton(
                      tooltip: '검색 지우기', icon: const Icon(Icons.clear),
                      onPressed: () => setState(() => searchController.clear()),
                    ),
                    border: const OutlineInputBorder(),
                  ),
                  onChanged: (_) => setState(() {}),
                ),
              ),
              SizedBox(
                width: constraints.maxWidth,
                child: DropdownButtonFormField<String>(
                  value: availableProblemCategories(problems).any((value) => value == selectedCategory)
                      ? selectedCategory : null,
                  hint: const Text('전체'),
                  isExpanded: true,
                  decoration: const InputDecoration(labelText: '문제 유형', border: OutlineInputBorder()),
                  items: [
                    const DropdownMenuItem<String>(value: null, child: Text('전체')),
                    ...availableProblemCategories(problems).map((category) =>
                      DropdownMenuItem(value: category, child: Text(category))),
                  ],
                  onChanged: (value) => setState(() => selectedCategory = value),
                ),
              ),
              SizedBox(
                width: width,
                child: DropdownButtonFormField<DifficultyFilter>(
                  value: selectedDifficulty,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    labelText: '난이도',
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(value: DifficultyFilter.all, child: Text('전체')),
                    DropdownMenuItem(value: DifficultyFilter.easy, child: Text('쉬움')),
                    DropdownMenuItem(value: DifficultyFilter.medium, child: Text('보통')),
                    DropdownMenuItem(value: DifficultyFilter.hard, child: Text('어려움')),
                  ],
                  onChanged: (value) {
                    if (value == null) return;
                    setState(() => selectedDifficulty = value);
                  },
                ),
              ),
              SizedBox(
                width: width,
                child: DropdownButtonFormField<SolvedFilter>(
                  value: selectedSolved,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    labelText: '해결 여부',
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(value: SolvedFilter.all, child: Text('전체')),
                    DropdownMenuItem(value: SolvedFilter.solved, child: Text('푼 문제만')),
                    DropdownMenuItem(value: SolvedFilter.unsolved, child: Text('풀지 않은 문제만')),
                  ],
                  onChanged: (value) {
                    if (value == null) return;
                    setState(() => selectedSolved = value);
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  /// problemCard: 이 기능의 화면 상태·요청·데이터 처리를 담당합니다.
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
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
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

  /// errorView: 이 기능의 화면 상태·요청·데이터 처리를 담당합니다.
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

  /// emptyView: 이 기능의 화면 상태·요청·데이터 처리를 담당합니다.
  Widget emptyView() {
    return const Center(
      child: Text('등록된 문제가 없습니다.'),
    );
  }

  @override
  /// build: 화면 위젯 구조를 구성합니다.
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('러닝패스'),
        actions: [
          const ThemeSettingsButton(),
          IconButton(
            tooltip: '학습 통계', icon: const Icon(Icons.bar_chart),
            onPressed: () => Navigator.push(context, MaterialPageRoute(
              builder: (_) => StatisticsScreen(userId: widget.userId),
            )),
          ),
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

          final filtered = filterProblems(
            problems,
            difficulty: selectedDifficulty,
            solved: selectedSolved,
            query: searchController.text,
            category: availableProblemCategories(problems).contains(selectedCategory) ? selectedCategory : null,
          );
          return ListView.builder(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            itemCount: filtered.isEmpty ? 4 : filtered.length + 3,
            itemBuilder: (context, index) {
              if (index == 0) return header(problems.length);
              if (index == 1) return filterControls(problems);
              if (index == 2) return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(children: [
                  Expanded(child: Text('전체 ${problems.length}개 중 ${filtered.length}개 표시')),
                  TextButton.icon(
                    onPressed: () async {
                      await Navigator.push(context, MaterialPageRoute(
                        builder: (_) => ReviewListScreen(userId: widget.userId),
                      ));
                      if (mounted) setState(() => futureProblems = ProblemApi.fetchProblems(widget.userId));
                    },
                    icon: const Icon(Icons.menu_book), label: const Text('오답 복습'),
                  ),
                  TextButton(
                    onPressed: () => setState(() {
                      searchController.clear();
                      selectedCategory = null;
                      selectedDifficulty = DifficultyFilter.all;
                      selectedSolved = SolvedFilter.all;
                    }),
                    child: const Text('초기화'),
                  ),
                ]),
              );
              if (filtered.isEmpty) return const Padding(
                padding: EdgeInsets.all(24),
                child: Center(child: Text('선택한 조건에 맞는 문제가 없습니다.')),
              );
              return problemCard(context, filtered[index - 3]);
            },
          );
        },
      ),
    );
  }
}