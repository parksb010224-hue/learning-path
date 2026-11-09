// 파일 역할: 채점 작업별 상태와 테스트케이스 진행률 데이터 모델
// 주요 선언부에는 담당 기능을 설명하는 한국어 주석을 추가했습니다.
import 'submission_response.dart';

/// progressResultLabel: 이 기능의 화면 상태·요청·데이터 처리를 담당합니다.
String progressResultLabel(String result) {
  const labels = {
    'PENDING': '대기', 'RUNNING': '채점 중', 'ACCEPTED': '정답',
    'WRONG_ANSWER': '오답', 'RUNTIME_ERROR': '실행 오류',
    'TIME_LIMIT_EXCEEDED': '시간 초과', 'JUDGE_ERROR': '채점 중단',
  };
  return labels[result] ?? result;
}

/// ProgressCase: 이 기능의 화면 상태·요청·데이터 처리를 담당합니다.
class ProgressCase {
  final int number;
  final bool isSample;
  final String result;
  const ProgressCase({required this.number, required this.isSample, required this.result});
  factory ProgressCase.fromJson(Map<String, dynamic> json) => ProgressCase(
    number: (json['number'] as num).toInt(),
    isSample: json['is_sample'] == true,
    result: json['result'] as String,
  );
}

/// SubmissionProgress: 이 기능의 화면 상태·요청·데이터 처리를 담당합니다.
class SubmissionProgress {
  final String jobId;
  final String status;
  final int totalCount;
  final int completedCount;
  final int passedCount;
  final List<ProgressCase> cases;
  final String? error;
  final SubmissionResponse? result;
  const SubmissionProgress({required this.jobId, required this.status,
    required this.totalCount, required this.completedCount, required this.passedCount,
    required this.cases, this.error, this.result});
  bool get completed => status == 'COMPLETED';
  bool get failed => status == 'FAILED';
  factory SubmissionProgress.fromJson(Map<String, dynamic> json) => SubmissionProgress(
    jobId: json['job_id'] as String,
    status: json['status'] as String,
    totalCount: (json['total_count'] as num).toInt(),
    completedCount: (json['completed_count'] as num).toInt(),
    passedCount: (json['passed_count'] as num).toInt(),
    cases: (json['cases'] as List).map((e) => ProgressCase.fromJson(Map<String, dynamic>.from(e as Map))).toList(),
    error: json['error'] as String?,
    result: json['result'] == null ? null : SubmissionResponse.fromJson(
      Map<String, dynamic>.from(json['result'] as Map)),
  );
}
