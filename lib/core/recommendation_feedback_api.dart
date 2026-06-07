import 'api_client.dart';

class RecommendationFeedbackApi {
  static Future<void> sendFeedback({
    required int userId,
    required int submissionId,
    required int recommendedProblemId,
    required String feedback,
  }) async {
    await ApiClient.post(
      '/recommendations/feedback',
      {
        'user_id': userId,
        'submission_id': submissionId,
        'recommended_problem_id': recommendedProblemId,
        'feedback': feedback,
      },
    );
  }
}