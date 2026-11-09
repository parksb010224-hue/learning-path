// 파일 역할: API 응답 데이터 모델 및 JSON 직렬화: problem
// 주요 선언부에는 담당 기능을 설명하는 한국어 주석을 추가했습니다.
class ProblemExample {
  final String inputData;
  final String expectedOutput;

  ProblemExample({
    required this.inputData,
    required this.expectedOutput,
  });

  factory ProblemExample.fromJson(Map<String, dynamic> json) {
    return ProblemExample(
      inputData: json['input_data'] ?? '',
      expectedOutput: json['expected_output'] ?? '',
    );
  }
}

/// Problem: 이 기능의 화면 상태·요청·데이터 처리를 담당합니다.
class Problem {
  final int id;
  final String title;
  final String difficulty;
  final String category;
  final String description;
  final String? inputDesc;
  final String? outputDesc;
  final List<ProblemExample> examples;
  final bool isSolved;
  final String? inputPattern;

  Problem({
    required this.id,
    required this.title,
    required this.difficulty,
    required this.category,
    required this.description,
    this.inputDesc,
    this.outputDesc,
    required this.examples,
    required this.isSolved,
    this.inputPattern,
  });

  factory Problem.fromJson(Map<String, dynamic> json) {
    return Problem(
      id: json['id'],
      title: json['title'] ?? '',
      difficulty: json['difficulty'] ?? '',
      category: json['category'] ?? '',
      description: json['description'] ?? '',
      inputDesc: json['input_desc'],
      outputDesc: json['output_desc'],
      examples: (json['examples'] as List<dynamic>? ?? [])
          .map((e) => ProblemExample.fromJson(e))
          .toList(),
      isSolved: json['is_solved'] == true || json['is_solved'] == 1,
      inputPattern: json['input_pattern'] as String?,
    );
  }
}