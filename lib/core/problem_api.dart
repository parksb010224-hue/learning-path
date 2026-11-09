// 파일 역할: HTTP 요청·저장소 등 앱의 외부 연동 계층: problem api
// 주요 선언부에는 담당 기능을 설명하는 한국어 주석을 추가했습니다.
import '../models/problem.dart';
import 'api_client.dart';

/// ProblemApi: 서버 API 호출을 캡슐화합니다.
class ProblemApi {
  /// fetchProblems: 이 기능의 화면 상태·요청·데이터 처리를 담당합니다.
  static Future<List<Problem>> fetchProblems(int userId) async {
    print('문제 목록 API 호출 시작');

    final data = await ApiClient.get('/problems?user_id=$userId');

    print('문제 목록 API 응답: $data');

    return (data as List)
        .map((e) => Problem.fromJson(e))
        .toList();
  }

  /// fetchProblemDetail: 이 기능의 화면 상태·요청·데이터 처리를 담당합니다.
  static Future<Problem> fetchProblemDetail(int problemId) async {
    final data = await ApiClient.get('/problems/$problemId');

    return Problem.fromJson(data);
  }
}