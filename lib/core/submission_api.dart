import 'dart:convert';
import 'package:http/http.dart' as http;

import '../models/submission_response.dart';

class SubmissionApi {
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
    );

    if (response.statusCode == 200) {
      return SubmissionResponse.fromJson(
        jsonDecode(response.body),
      );
    } else {
      throw Exception('제출 실패: ${response.statusCode}');
    }
  }
}