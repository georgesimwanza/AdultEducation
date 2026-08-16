import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:sqflite/sqflite.dart';

/// Handles answering a quiz offline-first: the student's answers are saved
/// locally the instant they finish, then pushed to the server immediately
/// if there's a connection — or left queued (synced = 0) for
/// syncPendingSubmissions() to pick up later. Kept separate from
/// QuizService, which only fetches/creates/edits quiz definitions.
class QuizSubmissionService {
  static const String _base = 'http://10.0.2.2:8080/api';
  final Database db;
  final Dio dio;

  QuizSubmissionService({required this.db, Dio? dio}) : dio = dio ?? Dio();

  /// Already answered this quiz — locally or synced — handy for showing
  /// "already submitted" in the UI instead of letting them retake it.
  Future<bool> hasSubmitted(int quizId, String email) async {
    final rows = await db.query(
      'quiz_submissions',
      where: 'quizId = ? AND email = ?',
      whereArgs: [quizId, email],
    );
    return rows.isNotEmpty;
  }

  Future<void> submitQuiz({
    required int quizId,
    required String email,
    required Map<String, dynamic> answers, // questionId -> selected answer
    int? score,
  }) async {
    final localId = 'local_${DateTime.now().millisecondsSinceEpoch}';
    await db.insert('quiz_submissions', {
      'id': localId,
      'quizId': quizId,
      'email': email,
      'answersJson': jsonEncode(answers),
      'score': score,
      'synced': 0,
      'submittedAt': DateTime.now().millisecondsSinceEpoch,
    });

    await _pushSubmission(localId, quizId, email, answers, score);
  }

  /// Call this on app startup (after connectivity's confirmed) or whenever
  /// you get a "back online" signal, to flush anything answered offline.
  Future<void> syncPendingSubmissions() async {
    final pending = await db.query('quiz_submissions', where: 'synced = 0');
    for (final row in pending) {
      final answers =
          jsonDecode(row['answersJson'] as String) as Map<String, dynamic>;
      await _pushSubmission(
        row['id'] as String,
        row['quizId'] as int,
        row['email'] as String,
        answers,
        row['score'] as int?,
      );
    }
  }

  Future<void> _pushSubmission(
    String localId,
    int quizId,
    String email,
    Map<String, dynamic> answers,
    int? score,
  ) async {
    try {
      await dio.post(
        '$_base/quiz/submissions',
        data: {
          'quizId': quizId,
          'studentEmail': email,
          'answersJson': jsonEncode(answers),
          if (score != null) 'score': score,
        },
      );
      await db.update(
        'quiz_submissions',
        {'synced': 1},
        where: 'id = ?',
        whereArgs: [localId],
      );
      print('✅ Quiz submission synced for quiz $quizId');
    } catch (e) {
      // Offline — stays queued with synced = 0, retried later.
      print('⏳ Quiz submission for quiz $quizId queued (offline): $e');
    }
  }
}
