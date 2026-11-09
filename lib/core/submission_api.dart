// 파일 역할: 제출·예제 실행·채점 진행률 조회 API 연결
// 주요 선언부에는 담당 기능을 설명하는 한국어 주석을 추가했습니다.
import 'dart:convert';
import 'package:http/http.dart' as http;

import '../models/submission_response.dart';
import '../models/submission_progress.dart';
import '../models/example_run_result.dart';

/// SubmissionApi: 서버 API 호출을 캡슐화합니다.
class SubmissionApi {
  /// _readResponse: 화면/모델 내부에서만 사용하는 보조 처리입니다.
  static Map<String, dynamic> _readResponse(http.Response response) {
    Map<String, dynamic>? data;
    try { data = Map<String, dynamic>.from(jsonDecode(response.body) as Map); }
    catch (_) { /* HTTP status below covers non-JSON proxy/server failures. */ }
    if (response.statusCode < 200 || response.statusCode >= 300) {
      final detail = data?['detail'];
      throw Exception(detail is String ? detail : '채점 요청 실패 (${response.statusCode})');
    }
    if (data == null) throw Exception('서버 응답을 읽지 못했습니다.');
    return data;
  }

  /// startSubmission: 이 기능의 화면 상태·요청·데이터 처리를 담당합니다.
  static Future<SubmissionProgress> startSubmission({
    required int userId, required int problemId, required String sourceCode,
    required String requestKey, http.Client? client,
  }) async {
    final uri = Uri.parse('http://127.0.0.1:8000/submission-jobs');
    final body = jsonEncode({'user_id': userId, 'problem_id': problemId,
      'source_code': sourceCode, 'language': 'python', 'request_key': requestKey});
    final response = await (client == null
      ? http.post(uri, headers: {'Content-Type': 'application/json'}, body: body)
      : client.post(uri, headers: {'Content-Type': 'application/json'}, body: body))
      .timeout(const Duration(seconds: 20));
    return SubmissionProgress.fromJson(_readResponse(response));
  }

  /// fetchProgress: 이 기능의 화면 상태·요청·데이터 처리를 담당합니다.
  static Future<SubmissionProgress> fetchProgress({
    required String jobId, required int userId, http.Client? client,
  }) async {
    final uri = Uri.parse('http://127.0.0.1:8000/submission-jobs/${Uri.encodeComponent(jobId)}')
      .replace(queryParameters: {'user_id': '$userId'});
    final response = await (client == null ? http.get(uri) : client.get(uri))
      .timeout(const Duration(seconds: 15));
    return SubmissionProgress.fromJson(_readResponse(response));
  }

  /// submitCode: 이 기능의 화면 상태·요청·데이터 처리를 담당합니다.
  static Future<SubmissionResponse> submitCode({
    required int userId,
    required int problemId,
    required String sourceCode,
  }) async {
    print('API USER ID: $userId');
    final response = await http.post(
      Uri.parse('http://127.0.0.1:8000/submissions'),
      headers: {
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'user_id': userId,
        'problem_id': problemId,
        'source_code': sourceCode,
        'language': 'python',
      }),
    ).timeout(const Duration(seconds: 120));

    if (response.statusCode == 200) {
      return SubmissionResponse.fromJson(
        jsonDecode(response.body),
      );
    } else {
      String message = '제출 실패 (${response.statusCode})';
      try {
        final data = jsonDecode(response.body);
        if (data is Map && data['detail'] is String) message = data['detail'];
      } catch (_) { /* Preserve the HTTP status for non-JSON failures. */ }
      throw Exception(message);
    }
  }
  /// fetchSubmission: 이 기능의 화면 상태·요청·데이터 처리를 담당합니다.
  static Future<Map<String, dynamic>> fetchSubmission({
    required int userId, required int submissionId,
  }) async {
    final response = await http.get(Uri.parse(
      'http://127.0.0.1:8000/submissions/$userId/$submissionId',
    )).timeout(const Duration(seconds: 30));
    if (response.statusCode != 200) throw Exception('제출 코드를 불러오지 못했습니다.');
    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  /// runExamples: 이 기능의 화면 상태·요청·데이터 처리를 담당합니다.
  static Future<ExampleRunResult> runExamples({
    required int problemId, required String sourceCode,
  }) async {
    final response = await http.post(
      Uri.parse('http://127.0.0.1:8000/examples/run'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'problem_id': problemId, 'source_code': sourceCode, 'language': 'python',
      }),
    ).timeout(const Duration(seconds: 120));
    if (response.statusCode != 200) {
      final data = jsonDecode(response.body);
      throw Exception(data['detail'] ?? '예제 실행에 실패했습니다.');
    }
    return ExampleRunResult.fromJson(jsonDecode(response.body));
  }
}