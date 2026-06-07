import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiClient {
  static const String baseUrl = 'http://127.0.0.1:8000';

  static Future<dynamic> get(String path) async {
    print('GET 요청 시작: $baseUrl$path');

    final response = await http
        .get(Uri.parse('$baseUrl$path'))
        .timeout(const Duration(seconds: 30));

    print('GET 상태코드: ${response.statusCode}');
    print('GET 응답본문: ${response.body}');

    return jsonDecode(response.body);
  }

  static Future<dynamic> post(String path, Map<String, dynamic> body) async {
    print('POST 요청 시작: $baseUrl$path');
    print('POST 바디: $body');

    final response = await http
        .post(
      Uri.parse('$baseUrl$path'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(body),
    )
        .timeout(const Duration(seconds: 30));

    print('POST 상태코드: ${response.statusCode}');
    print('POST 응답본문: ${response.body}');

    return jsonDecode(response.body);
  }
}