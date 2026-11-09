// 파일 역할: API 응답 데이터 모델 및 JSON 직렬화: submission response
// 주요 선언부에는 담당 기능을 설명하는 한국어 주석을 추가했습니다.
class CaseResult {
  final int testCaseId;
  final String result;
  final bool isSample;
  final String? stderr;
  final String? actualOutput;
  final String? expectedOutput;

  CaseResult({
    required this.testCaseId,
    required this.result,
    this.isSample = true,
    this.stderr,
    this.actualOutput,
    this.expectedOutput,
  });

  factory CaseResult.fromJson(Map<String, dynamic> json) {
    return CaseResult(
      testCaseId: json['test_case_id'],
      result: json['result'],
      isSample: json['is_sample'] != false && json['is_sample'] != 0,
      stderr: json['stderr'],
      actualOutput: json['actual_output'],
      expectedOutput: json['expected_output'],
    );
  }
}

/// SubmissionResponse: 이 기능의 화면 상태·요청·데이터 처리를 담당합니다.
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