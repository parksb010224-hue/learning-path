// 파일 역할: API 응답 데이터 모델 및 JSON 직렬화: submission history
// 주요 선언부에는 담당 기능을 설명하는 한국어 주석을 추가했습니다.
class SubmissionHistory {
  final int id;
  final int problemId;
  final String problemTitle;
  final String language;
  final String verdict;
  final int passedCount;
  final int totalCount;
  final String createdAt;
  final String? sourceCode;

  SubmissionHistory({
    required this.id,
    required this.problemId,
    required this.problemTitle,
    required this.language,
    required this.verdict,
    required this.passedCount,
    required this.totalCount,
    required this.createdAt,
    this.sourceCode,
  });

  factory SubmissionHistory.fromJson(Map<String, dynamic> json) {
    return SubmissionHistory(
      id: json['id'],
      problemId: json['problem_id'],
      problemTitle: json['problem_title'],
      language: json['language'],
      verdict: json['verdict'],
      passedCount: json['passed_count'],
      totalCount: json['total_count'],
      createdAt: json['created_at'].toString(),
      sourceCode: json['source_code'] as String?,
    );
  }
}