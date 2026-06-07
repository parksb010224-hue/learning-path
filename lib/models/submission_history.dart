class SubmissionHistory {
  final int id;
  final int problemId;
  final String problemTitle;
  final String language;
  final String verdict;
  final int passedCount;
  final int totalCount;
  final String createdAt;

  SubmissionHistory({
    required this.id,
    required this.problemId,
    required this.problemTitle,
    required this.language,
    required this.verdict,
    required this.passedCount,
    required this.totalCount,
    required this.createdAt,
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
    );
  }
}