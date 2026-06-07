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
    );
  }
}