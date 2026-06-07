import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/submission_history.dart';

class SubmissionHistoryApi {
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