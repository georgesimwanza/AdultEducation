import 'dart:convert';
import 'package:http/http.dart' as http;
import '../Model/quiz.dart';

/// Talks to the Spring Boot quiz API (QuizController / QuizService /
/// QuizRepository on the backend). This is the only file that knows the
/// request/response shapes — QuizAdminController just calls these methods.
class QuizService {
  QuizService({this.baseUrl = 'http://10.0.2.2:8080/api'});

  /// 10.0.2.2 is the special alias the Android emulator uses to reach
  /// "localhost" on your development machine — it is NOT a real network
  /// address. On a physical device or in production, replace this with
  /// your actual backend URL (e.g. your deployed API's https:// host).
  final String baseUrl;

  Future<List<Quiz>> fetchQuizzes({int? subjectId, int? institutionId}) async {
    final query = <String, String>{
      if (subjectId != null) 'courseId': '$subjectId',
      if (institutionId != null) 'institutionId': '$institutionId',
    };
    final uri = Uri.parse(
      '$baseUrl/quizzes',
    ).replace(queryParameters: query.isEmpty ? null : query);
    final response = await http.get(uri);
    _checkOk(response);
    final List<dynamic> data = jsonDecode(response.body) as List<dynamic>;
    return data
        .map((json) => Quiz.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  Future<Quiz> fetchQuiz(String id) async {
    final response = await http.get(Uri.parse('$baseUrl/quizzes/$id'));
    _checkOk(response);
    return Quiz.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
  }

  Future<Quiz> createQuiz(
    String title, {
    required int subjectId,
    required int institutionId,
    String description = '',
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/quizzes'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'title': title,
        'description': description,
        'courseId': subjectId,
        'institutionId': institutionId,
      }),
    );
    _checkOk(response);
    return Quiz.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
  }

  /// Sends the whole quiz — metadata plus the complete question list.
  /// The backend replaces the quiz's question list wholesale on each call
  /// (see QuizService.updateQuiz on the backend), which matches how
  /// QuizAdminController always builds a full, updated Quiz before saving.
  Future<Quiz> updateQuiz(Quiz quiz) async {
    final response = await http.put(
      Uri.parse('$baseUrl/quizzes/${quiz.id}'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(quiz.toJson()),
    );
    _checkOk(response);
    return Quiz.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
  }

  Future<void> deleteQuiz(String id) async {
    final response = await http.delete(Uri.parse('$baseUrl/quizzes/$id'));
    _checkOk(response);
  }

  void _checkOk(http.Response response) {
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(
        'Quiz API error ${response.statusCode}: ${response.body}',
      );
    }
  }
}
