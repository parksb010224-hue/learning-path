// 파일 역할: HTTP 요청·저장소 등 앱의 외부 연동 계층: recommendation api
// 주요 선언부에는 담당 기능을 설명하는 한국어 주석을 추가했습니다.
import 'api_client.dart';
import '../models/recommended_problem.dart';

/// RecommendationApi: 서버 API 호출을 캡슐화합니다.
class RecommendationApi {
  /// fetchAiRecommendations: 이 기능의 화면 상태·요청·데이터 처리를 담당합니다.
  static Future<List<RecommendedProblem>> fetchAiRecommendations(
    int submissionId, {
    required String verdict,
  }) async {
    if (verdict != 'ACCEPTED') return <RecommendedProblem>[];

    final data = await ApiClient.get('/recommendations/ai/$submissionId');

    return (data as List)
        .map((e) => RecommendedProblem.fromJson(e))
        .toList();
  }
}