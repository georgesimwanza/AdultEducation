import 'package:flutter/foundation.dart';
import '../Model/question.dart';
import '../Model/quiz.dart';

/// Holds all quiz admin state and mutation logic.
///
/// Purely in-memory for now — no backend yet, so quizzes reset when the
/// app restarts. When your API is ready, this is the only file that
/// needs to change: swap the in-memory list operations below for real
/// HTTP calls (e.g. through your existing lib/service folder).
class QuizAdminController extends ChangeNotifier {
  final List<Quiz> _quizzes = [];

  List<Quiz> get quizzes => List.unmodifiable(_quizzes);

  Quiz createQuiz(String title, {String description = ''}) {
    final quiz = Quiz(
      id: 'quiz_${DateTime.now().microsecondsSinceEpoch}',
      title: title,
      description: description,
    );
    _quizzes.add(quiz);
    notifyListeners();
    return quiz;
  }

  void updateQuiz(Quiz quiz) {
    final index = _quizzes.indexWhere((q) => q.id == quiz.id);
    if (index != -1) {
      _quizzes[index] = quiz;
      notifyListeners();
    }
  }

  void deleteQuiz(String id) {
    _quizzes.removeWhere((q) => q.id == id);
    notifyListeners();
  }

  /// Adds a new question, or replaces an existing one (matched by id).
  void upsertQuestion(Quiz quiz, Question question) {
    final existingIndex =
        quiz.questions.indexWhere((q) => q.id == question.id);
    final newQuestions = [...quiz.questions];
    if (existingIndex == -1) {
      newQuestions.add(question);
    } else {
      newQuestions[existingIndex] = question;
    }
    updateQuiz(quiz.copyWith(questions: newQuestions));
  }

  void removeQuestion(Quiz quiz, String questionId) {
    final newQuestions =
        quiz.questions.where((q) => q.id != questionId).toList();
    updateQuiz(quiz.copyWith(questions: newQuestions));
  }

  void reorderQuestions(Quiz quiz, int oldIndex, int newIndex) {
    final newQuestions = [...quiz.questions];
    if (newIndex > oldIndex) newIndex -= 1;
    final item = newQuestions.removeAt(oldIndex);
    newQuestions.insert(newIndex, item);
    updateQuiz(quiz.copyWith(questions: newQuestions));
  }
}
