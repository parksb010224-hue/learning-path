class RecommendedProblem {
  final int id;
  final String title;
  final String difficulty;
  final String category;
  final String description;
  final String reason;

  RecommendedProblem({
    required this.id,
    required this.title,
    required this.difficulty,
    required this.category,
    required this.description,
    required this.reason,
  });

  factory RecommendedProblem.fromJson(Map<String, dynamic> json) {
    return RecommendedProblem(
      id: json['id'],
      title: json['title'] ?? '',
      difficulty: json['difficulty'] ?? '',
      category: json['category'] ?? '',
      description: json['description'] ?? '',
      reason: json['reason'] ?? '',
    );
  }
}