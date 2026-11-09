// 파일 역할: API 응답 데이터 모델 및 JSON 직렬화: ai analysis
// 주요 선언부에는 담당 기능을 설명하는 한국어 주석을 추가했습니다.
class AIAnalysis {
  final String wrongType;
  final String analysisText;
  final String hint1;
  final String hint2;
  final String hint3;
  final String retryGuide;
  final String timeComplexity;
  final String improvementSuggestion;
  final String counterExample;

  AIAnalysis({
    required this.wrongType,
    required this.analysisText,
    required this.hint1,
    required this.hint2,
    required this.hint3,
    required this.retryGuide,
    required this.timeComplexity,
    required this.improvementSuggestion,
    required this.counterExample,
  });

  factory AIAnalysis.fromJson(Map<String, dynamic> json) {
    return AIAnalysis(
      wrongType: json['wrong_type'] ?? '',
      analysisText: json['analysis_text'] ?? '',
      hint1: json['hint1'] ?? '',
      hint2: json['hint2'] ?? '',
      hint3: json['hint3'] ?? '',
      retryGuide: json['retry_guide'] ?? '',
      timeComplexity: json['time_complexity'] ?? '',
      improvementSuggestion: json['improvement_suggestion'] ?? '',
      counterExample: json['counter_example'] ?? '',
    );
  }
}