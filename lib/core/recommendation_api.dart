import 'api_client.dart';
import '../models/recommended_problem.dart';

class RecommendationApi {
  static Future<List<RecommendedProblem>> fetchAiRecommendations(
      int submissionId,
      ) async {
    final data = await ApiClient.get('/recommendations/ai/$submissionId');

    return (data as List)
        .map((e) => RecommendedProblem.fromJson(e))
        .toList();
  }
}