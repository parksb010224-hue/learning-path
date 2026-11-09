// 파일 역할: 공통 GET/POST 요청과 JSON 응답 변환
// 주요 선언부에는 담당 기능을 설명하는 한국어 주석을 추가했습니다.
import 'dart:convert';
import 'package:http/http.dart' as http;

/// ApiClient: 이 기능의 화면 상태·요청·데이터 처리를 담당합니다.
class ApiClient {
  static const String baseUrl = 'http://127.0.0.1:8000';

  /// get: 이 기능의 화면 상태·요청·데이터 처리를 담당합니다.
  static Future<dynamic> get(String path) async {

    final response = await http
        .get(Uri.parse('$baseUrl$path'))
        .timeout(const Duration(seconds: 30));


    return jsonDecode(response.body);
  }

  /// post: 이 기능의 화면 상태·요청·데이터 처리를 담당합니다.
  static Future<dynamic> post(String path, Map<String, dynamic> body) async {


    final response = await http
        .post(
      Uri.parse('$baseUrl$path'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(body),
    )
        .timeout(const Duration(seconds: 30));


    return jsonDecode(response.body);
  }
}