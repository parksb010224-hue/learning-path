import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/ai_analysis.dart';

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