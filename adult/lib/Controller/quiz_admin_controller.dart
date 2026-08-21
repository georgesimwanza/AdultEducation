import 'package:flutter/foundation.dart';
import '../Model/question.dart';
import '../Model/quiz.dart';
import '../service/quiz_service.dart';

/// Holds all quiz admin state and mutation logic, backed by [QuizService]
/// (which talks to the Spring Boot API). Screens read from this via
/// Provider/Consumer and never call QuizService directly.
class QuizAdminController extends ChangeNotifier {
  QuizAdminController({QuizService? service})
    : _service = service ?? QuizService();
  final QuizService _service;
  List<Quiz> _quizzes = [];
  bool _isLoading = false;
  String? _errorMessage;
  List<Quiz> get quizzes => List.unmodifiable(_quizzes);
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  Future<void> loadQuizzes() async {
    _isLoading = true;
    notifyListeners();
    try {
      _quizzes = await _service.fetchQuizzes();
      _errorMessage = null;
    } catch (e) {
      _errorMessage = 'Failed to load quizzes: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<Quiz> createQuiz(
    String title, {
    required int subjectId,
    required int institutionId,
    required int programmeId,
    String description = '',
  }) async {
    final quiz = await _service.createQuiz(
      title,
      subjectId: subjectId,
      institutionId: institutionId,
      programmeId: programmeId,
      description: description,
    );
    _quizzes = [..._quizzes, quiz];
    notifyListeners();
    return quiz;
  }

  Future<void> updateQuiz(Quiz quiz) async {
    final updated = await _service.updateQuiz(quiz);
    _quizzes = _quizzes.map((q) => q.id == updated.id ? updated : q).toList();
    notifyListeners();
  }

  Future<void> deleteQuiz(String id) async {
    await _service.deleteQuiz(id);
    _quizzes = _quizzes.where((q) => q.id != id).toList();
    notifyListeners();
  }

  /// Adds a new question, or replaces an existing one (matched by id),
  /// then saves the whole quiz via [updateQuiz].
  Future<void> upsertQuestion(Quiz quiz, Question question) async {
    final existingIndex = quiz.questions.indexWhere((q) => q.id == question.id);
    final newQuestions = [...quiz.questions];
    if (existingIndex == -1) {
      newQuestions.add(question);
    } else {
      newQuestions[existingIndex] = question;
    }
    await updateQuiz(quiz.copyWith(questions: newQuestions));
  }

  Future<void> removeQuestion(Quiz quiz, String questionId) async {
    final newQuestions = quiz.questions
        .where((q) => q.id != questionId)
        .toList();
    await updateQuiz(quiz.copyWith(questions: newQuestions));
  }

  Future<void> reorderQuestions(Quiz quiz, int oldIndex, int newIndex) async {
    final newQuestions = [...quiz.questions];
    if (newIndex > oldIndex) newIndex -= 1;
    final item = newQuestions.removeAt(oldIndex);
    newQuestions.insert(newIndex, item);
    await updateQuiz(quiz.copyWith(questions: newQuestions));
  }
}
