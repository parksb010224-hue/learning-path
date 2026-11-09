// 파일 역할: API 응답 데이터 모델 및 JSON 직렬화: recommended problem
// 주요 선언부에는 담당 기능을 설명하는 한국어 주석을 추가했습니다.
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