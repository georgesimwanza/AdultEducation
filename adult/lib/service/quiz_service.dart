import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:sqflite/sqflite.dart';
import '../Model/quiz.dart';

/// Talks to the Spring Boot quiz API (QuizController / QuizService /
/// QuizRepository on the backend). This is the only file that knows the
/// request/response shapes — QuizAdminController just calls these methods.
///
/// Pass [db] (the same local db SyncService/ScheduleService use) to get
/// offline support on fetchQuizzes/fetchQuiz: a successful network call
/// caches results locally, and a failed one falls back to whatever's
/// cached from the last sync. createQuiz/updateQuiz/deleteQuiz stay
/// network-only — admin editing isn't meant to work offline.
class QuizService {
  QuizService({this.baseUrl = 'http://10.0.2.2:8080/api', this.db});

  /// 10.0.2.2 is the special alias the Android emulator uses to reach
  /// "localhost" on your development machine — it is NOT a real network
  /// address. On a physical device or in production, replace this with
  /// your actual backend URL (e.g. your deployed API's https:// host).
  final String baseUrl;
  final Database? db;

  Future<List<Quiz>> fetchQuizzes({
    int? subjectId,
    int? institutionId,
    int? programmeId,
  }) async {
    try {
      final query = <String, String>{
        if (subjectId != null) 'courseId': '$subjectId',
        if (institutionId != null) 'institutionId': '$institutionId',
        if (programmeId != null) 'programmeId': '$programmeId',
      };
      final uri = Uri.parse(
        '$baseUrl/quizzes',
      ).replace(queryParameters: query.isEmpty ? null : query);
      // Timeout so a weak connection falls back to the cache instead of
      // spinning forever.
      final response = await http.get(uri).timeout(const Duration(seconds: 8));
      _checkOk(response);
      final List<dynamic> data = jsonDecode(response.body) as List<dynamic>;

      if (db != null) {
        for (final item in data) {
          await _cacheQuiz(item as Map<String, dynamic>);
        }
      }

      return data
          .map((json) => Quiz.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      if (db == null) rethrow;
      // Offline — serve whatever was cached during the last sync.
      return _fetchQuizzesOffline(
        subjectId: subjectId,
        institutionId: institutionId,
        programmeId: programmeId,
      );
    }
  }

  Future<Quiz> fetchQuiz(String id) async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/quizzes/$id'));
      _checkOk(response);
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      if (db != null) await _cacheQuiz(json);
      return Quiz.fromJson(json);
    } catch (e) {
      if (db == null) rethrow;
      final quizId = int.tryParse(id);
      if (quizId == null) rethrow;
      final rows = await db!.query(
        'quizzes',
        where: 'id = ?',
        whereArgs: [quizId],
      );
      if (rows.isEmpty) rethrow;
      return Quiz.fromJson(
        jsonDecode(rows.first['data'] as String) as Map<String, dynamic>,
      );
    }
  }

  Future<Quiz> createQuiz(
      String title, {
        required int subjectId,
        required int institutionId,
        required int programmeId,
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
        'programmeId': programmeId,
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

  // ---------- local cache (only used when db is provided) ----------

  Future<void> _cacheQuiz(Map<String, dynamic> json) async {
    // The API returns QuizDto: id is a String and the foreign keys are flat
    // (courseId / institutionId / programmeId), not nested objects.
    final id = int.tryParse('${json['id']}');
    if (id == null) return;
    await db!.insert('quizzes', {
      'id': id,
      'courseId': json['courseId'],
      'institutionId': json['institutionId'],
      'programmeId': json['programmeId'],
      'data': jsonEncode(json),
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<Quiz>> _fetchQuizzesOffline({
    int? subjectId,
    int? institutionId,
    int? programmeId,
  }) async {
    final where = <String>[];
    final args = <Object>[];
    if (subjectId != null) {
      where.add('courseId = ?');
      args.add(subjectId);
    }
    if (institutionId != null) {
      where.add('institutionId = ?');
      args.add(institutionId);
    }
    if (programmeId != null) {
      where.add('programmeId = ?');
      args.add(programmeId);
    }

    final rows = await db!.query(
      'quizzes',
      where: where.isEmpty ? null : where.join(' AND '),
      whereArgs: where.isEmpty ? null : args,
    );
    return rows
        .map(
          (r) => Quiz.fromJson(
        jsonDecode(r['data'] as String) as Map<String, dynamic>,
      ),
    )
        .toList();
  }
}