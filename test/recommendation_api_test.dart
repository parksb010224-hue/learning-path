// 파일 역할: Flutter 단위·위젯 테스트: recommendation api test
// 주요 선언부에는 담당 기능을 설명하는 한국어 주석을 추가했습니다.
import 'package:flutter_test/flutter_test.dart';
import '../lib/core/recommendation_api.dart';

/// main: 이 기능의 화면 상태·요청·데이터 처리를 담당합니다.
void main() {
  for (final verdict in ['WRONG_ANSWER', 'RUNTIME_ERROR', 'TIME_LIMIT_EXCEEDED', '']) {
    test('$verdict returns no recommendations without contacting the API', () async {
      // No HTTP mock or backend is needed: non-accepted submissions return
      // before ApiClient.get can run.
      expect(await RecommendationApi.fetchAiRecommendations(
        1, verdict: verdict,
      ), isEmpty);
    });
  }
}
