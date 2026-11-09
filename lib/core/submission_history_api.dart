// 파일 역할: HTTP 요청·저장소 등 앱의 외부 연동 계층: submission history api
// 주요 선언부에는 담당 기능을 설명하는 한국어 주석을 추가했습니다.
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/submission_history.dart';

/// SubmissionHistoryApi: 서버 API 호출을 캡슐화합니다.
class SubmissionHistoryApi {
  /// fetchSubmissions: 이 기능의 화면 상태·요청·데이터 처리를 담당합니다.
  static Future<List<SubmissionHistory>> fetchSubmissions({
    int userId = 1,
  }) async {
    final response = await http.get(
      Uri.parse('http://127.0.0.1:8000/submissions/$userId'),
    );

    if (response.statusCode == 200) {
      final List data = jsonDecode(response.body);
      return data.map((e) => SubmissionHistory.fromJson(e)).toList();
    } else {
      throw Exception('제출 기록 조회 실패');
    }
  }
}