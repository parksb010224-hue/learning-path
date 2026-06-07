class CaseResult {
  final int testCaseId;
  final String result;
  final String? actualOutput;
  final String? expectedOutput;

  CaseResult({
    required this.testCaseId,
    required this.result,
    this.actualOutput,
    this.expectedOutput,
  });

  factory CaseResult.fromJson(Map<String, dynamic> json) {
    return CaseResult(
      testCaseId: json['test_case_id'],
      result: json['result'],
      actualOutput: json['actual_output'],
      expectedOutput: json['expected_output'],
    );
  }
}

class SubmissionResponse {
  final int submissionId;
  final String verdict;
  final int passedCount;
  final int totalCount;
  final List<CaseResult> results;

  SubmissionResponse({
    required this.submissionId,
    required this.verdict,
    required this.passedCount,
    required this.totalCount,
    required this.results,
  });

  factory SubmissionResponse.fromJson(Map<String, dynamic> json) {
    return SubmissionResponse(
      submissionId: json['submission_id'],
      verdict: json['verdict'],
      passedCount: json['passed_count'],
      totalCount: json['total_count'],
      results: (json['results'] as List)
          .map((e) => CaseResult.fromJson(e))
          .toList(),
    );
  }
}