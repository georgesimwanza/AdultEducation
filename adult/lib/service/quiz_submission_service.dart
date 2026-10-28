import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:sqflite/sqflite.dart';
import 'package:adult/service/api_config.dart';

/// Handles offline-first submission of quiz answers.
///
/// When a student submits a quiz:
/// 1. The submission is immediately stored in the local SQLite database.
/// 2. The submission is marked as unsynchronized using `synced = 0`.
/// 3. The application attempts to send the submission to the backend.
/// 4. If the request succeeds, the local record is marked as synchronized
///    using `synced = 1`.
/// 5. If there is no internet connection or the server cannot be reached,
///    the submission remains in the local database and can be synchronized
///    later using [syncPendingSubmissions].
///
/// This service is intentionally separate from `QuizService`.
/// `QuizService` is responsible for managing quiz definitions, while this
/// service handles student quiz submissions.
class QuizSubmissionService {
  /// Base URL used to communicate with the backend API.
  ///
  /// `10.0.2.2` is used when running the Flutter application on
  /// an Android emulator because it points to the host machine's
  /// localhost.
  static const String _base = '$kBackendHost/api';

  /// Local SQLite database used to store quiz submissions.
  ///
  /// The database allows submissions to be saved even when
  /// the device is offline.
  final Database db;

  /// HTTP client used to communicate with the backend server.
  final Dio dio;

  /// Creates a [QuizSubmissionService].
  ///
  /// [db] is required because the service needs access to the
  /// local SQLite database.
  ///
  /// [dio] is optional. If no Dio instance is supplied, a new
  /// Dio instance is created automatically.
  QuizSubmissionService({required this.db, Dio? dio}) : dio = dio ?? Dio();

  /// Checks whether a student has already submitted a particular quiz.
  ///
  /// The check is performed against the local SQLite database.
  ///
  /// A submission is considered to exist whether it has already
  /// been synchronized with the server or is still waiting to
  /// be synchronized.
  ///
  /// This can be used by the UI to prevent a student from
  /// attempting the same quiz multiple times.
  ///
  /// Returns `true` when a matching submission exists;
  /// otherwise returns `false`.
  Future<bool> hasSubmitted(int quizId, String email) async {
    // Search the quiz_submissions table for a record
    // belonging to the specified quiz and student.
    final rows = await db.query(
      'quiz_submissions',

      // Only return records matching both the quiz ID
      // and the student's email address.
      where: 'quizId = ? AND email = ?',

      // Values that replace the ? placeholders in the query.
      whereArgs: [quizId, email],
    );

    // If at least one record exists, the student has
    // already submitted this quiz.
    return rows.isNotEmpty;
  }

  /// Saves and submits a student's quiz answers.
  ///
  /// The submission is first written to SQLite before any
  /// network request is attempted. This is important for the
  /// offline-first design because the student's answers are
  /// not lost when the device is offline.
  ///
  /// [quizId] identifies the quiz being submitted.
  ///
  /// [email] identifies the student submitting the quiz.
  ///
  /// [answers] contains the student's answers, where the key
  /// represents the question ID and the value represents the
  /// selected or entered answer.
  ///
  /// [score] optionally contains the student's calculated score.
  Future<void> submitQuiz({
    required int quizId,
    required String email,
    required Map<String, dynamic> answers,
    int? score,
  }) async {
    // Generate a unique local identifier for this submission.
    //
    // The timestamp helps prevent collisions between local
    // submissions created at different times.
    final localId = 'local_${DateTime.now().millisecondsSinceEpoch}';

    // Save the submission locally before attempting to contact
    // the backend.
    await db.insert('quiz_submissions', {
      // Unique identifier for the local submission.
      'id': localId,

      // ID of the quiz being submitted.
      'quizId': quizId,

      // Email address of the student.
      'email': email,

      // Convert the answers map into a JSON string because
      // SQLite does not directly store Dart Map objects.
      'answersJson': jsonEncode(answers),

      // Store the score when one was provided.
      'score': score,

      // `0` means the submission has not yet been
      // successfully synchronized with the server.
      'synced': 0,

      // Store the submission time as a Unix timestamp
      // in milliseconds.
      'submittedAt': DateTime.now().millisecondsSinceEpoch,
    });

    // Immediately attempt to send the locally stored submission
    // to the backend.
    //
    // If the request fails, _pushSubmission() catches the error
    // and leaves `synced` as 0 so it can be retried later.
    await _pushSubmission(localId, quizId, email, answers, score);
  }

  /// Synchronizes all quiz submissions that have not yet
  /// been successfully sent to the backend.
  ///
  /// This method should be called:
  /// - When the application starts and internet connectivity
  ///   has been confirmed.
  /// - When the device comes back online.
  /// - At another appropriate synchronization point.
  ///
  /// Records with `synced = 0` are considered pending.
  Future<void> syncPendingSubmissions() async {
    // Retrieve all submissions that have not yet been
    // synchronized with the backend.
    final pending = await db.query('quiz_submissions', where: 'synced = 0');

    // Process each pending submission one at a time.
    for (final row in pending) {
      // Convert the JSON string stored in SQLite back into
      // a Dart Map so it can be sent to the backend.
      final answers =
          jsonDecode(row['answersJson'] as String) as Map<String, dynamic>;

      // Attempt to synchronize this submission.
      await _pushSubmission(
        row['id'] as String,
        row['quizId'] as int,
        row['email'] as String,
        answers,
        row['score'] as int?,
      );
    }
  }

  /// Sends one quiz submission to the backend.
  ///
  /// This is a private method because it is an internal
  /// implementation detail of the service.
  ///
  /// If the request succeeds:
  /// - The local submission is marked as synchronized.
  ///
  /// If the request fails:
  /// - The local submission remains with `synced = 0`.
  /// - The error is logged.
  /// - The submission can be retried later.
  Future<void> _pushSubmission(
    String localId,
    int quizId,
    String email,
    Map<String, dynamic> answers,
    int? score,
  ) async {
    try {
      // Send the quiz submission to the backend API.
      await dio.post(
        '$_base/quiz/submissions',

        // Convert the submission into the JSON structure
        // expected by the backend.
        data: {
          // Identify the quiz.
          'quizId': quizId,

          // Identify the student.
          'studentEmail': email,

          // Convert the answers map to JSON before sending it.
          'answersJson': jsonEncode(answers),

          // Only include the score when one is available.
          if (score != null) 'score': score,
        },
      );

      // The server accepted the submission successfully.
      //
      // Update the local record so that it is no longer
      // considered a pending submission.
      await db.update(
        'quiz_submissions',

        // Change synced from 0 to 1.
        {'synced': 1},

        // Only update the specific submission that was just synced.
        where: 'id = ?',

        // Replace the ? with the local submission ID.
        whereArgs: [localId],
      );

      // Log successful synchronization for debugging.
      print('✅ Quiz submission synced for quiz $quizId');
    } catch (e) {
      // The network request failed.
      //
      // The submission is deliberately NOT deleted and its
      // `synced` value is NOT changed. It therefore remains
      // in the local database with `synced = 0`.
      //
      // A later call to syncPendingSubmissions() can retry it.
      print(
        '⏳ Quiz submission for quiz $quizId '
        'queued (offline): $e',
      );
    }
  }
}
