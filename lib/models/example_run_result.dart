// 파일 역할: API 응답 데이터 모델 및 JSON 직렬화: example run result
// 주요 선언부에는 담당 기능을 설명하는 한국어 주석을 추가했습니다.
class ExampleRunCase {
  final int number;
  final String input;
  final String expected;
  final String actual;
  final String stderr;
  final String result;
  ExampleRunCase.fromJson(Map<String, dynamic> json)
      : number = json['example_number'],
        input = json['input_data'] ?? '',
        expected = json['expected_output'] ?? '',
        actual = json['actual_output'] ?? '',
        stderr = json['stderr'] ?? '',
        result = json['result'];
}

/// ExampleRunResult: 이 기능의 화면 상태·요청·데이터 처리를 담당합니다.
class ExampleRunResult {
  final int passedCount;
  final int totalCount;
  final List<ExampleRunCase> cases;
  ExampleRunResult.fromJson(Map<String, dynamic> json)
      : passedCount = json['passed_count'],
        totalCount = json['total_count'],
        cases = (json['results'] as List)
            .map((e) => ExampleRunCase.fromJson(e)).toList();
}
