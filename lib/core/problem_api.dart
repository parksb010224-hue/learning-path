import '../models/problem.dart';
import 'api_client.dart';

class ProblemApi {
  static Future<List<Problem>> fetchProblems(int userId) async {
    print('문제 목록 API 호출 시작');

    final data = await ApiClient.get('/problems?user_id=$userId');

    print('문제 목록 API 응답: $data');

    return (data as List)
        .map((e) => Problem.fromJson(e))
        .toList();
  }

  static Future<Problem> fetchProblemDetail(int problemId) async {
    final data = await ApiClient.get('/problems/$problemId');

    return Problem.fromJson(data);
  }
}