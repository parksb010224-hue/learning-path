import 'dart:convert';
import 'package:http/http.dart' as http;

class AuthApi {
  static const String baseUrl = 'http://127.0.0.1:8000';

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

  static Future<void> deleteUser(int userId) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/auth/users/$userId'),
    );

    if (response.statusCode != 200) {
      throw Exception(jsonDecode(response.body)['detail']);
    }
  }
}