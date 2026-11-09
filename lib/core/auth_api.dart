// 파일 역할: 회원가입 및 로그인 REST API 연결
// 주요 선언부에는 담당 기능을 설명하는 한국어 주석을 추가했습니다.
import 'dart:convert';
import 'package:http/http.dart' as http;

/// AuthApi: 서버 API 호출을 캡슐화합니다.
class AuthApi {
  static const String baseUrl = 'http://127.0.0.1:8000';

  /// register: 이 기능의 화면 상태·요청·데이터 처리를 담당합니다.
  static Future<Map<String, dynamic>> register({
    required String username,
    required String password,
    required String nickname,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/register'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'username': username,
        'password': password,
        'nickname': nickname,
      }),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception(jsonDecode(response.body)['detail']);
    }
  }

  /// login: 이 기능의 화면 상태·요청·데이터 처리를 담당합니다.
  static Future<Map<String, dynamic>> login({
    required String username,
    required String password,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'username': username,
        'password': password,
      }),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception(jsonDecode(response.body)['detail']);
    }
  }

  /// deleteUser: 이 기능의 화면 상태·요청·데이터 처리를 담당합니다.
  static Future<void> deleteUser(int userId) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/auth/users/$userId'),
    );

    if (response.statusCode != 200) {
      throw Exception(jsonDecode(response.body)['detail']);
    }
  }
}