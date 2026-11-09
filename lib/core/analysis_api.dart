// 파일 역할: HTTP 요청·저장소 등 앱의 외부 연동 계층: analysis api
// 주요 선언부에는 담당 기능을 설명하는 한국어 주석을 추가했습니다.
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/ai_analysis.dart';

/// AnalysisApi: 서버 API 호출을 캡슐화합니다.
class AnalysisApi {
  static const String baseUrl = 'http://127.0.0.1:8000';

  // AI 분석 생성
  static Future<AIAnalysis> analyze(int submissionId) async {
    final response = await http
        .post(
      Uri.parse('$baseUrl/analysis/$submissionId'),
    )
        .timeout(const Duration(seconds: 30));

    if (response.statusCode == 200) {
      return AIAnalysis.fromJson(
        jsonDecode(response.body),
      );
    } else {
      throw Exception('AI 분석 실패');
    }
  }

  // 기존 AI 분석 조회
  static Future<AIAnalysis> getAnalysis(int submissionId) async {
    final response = await http
        .get(
      Uri.parse('$baseUrl/analysis/$submissionId'),
    )
        .timeout(const Duration(seconds: 30));

    if (response.statusCode == 200) {
      return AIAnalysis.fromJson(
        jsonDecode(response.body),
      );
    } else {
      throw Exception('AI 분석 조회 실패');
    }
  }
}