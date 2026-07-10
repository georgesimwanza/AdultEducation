import 'question.dart';

/// A quiz is metadata plus an ordered list of mixed-type questions.
/// Because [Question] is sealed, [questions] can freely combine Multiple
/// Choice, True/False, Short Answer, and Essay questions in any order.
class Quiz {
  const Quiz({
    required this.id,
    required this.title,
    this.description = '',
    this.questions = const [],
    this.timeLimitMinutes,
    this.passingScorePercent = 50,
  });

  final String id;
  final String title;
  final String description;
  final List<Question> questions;

  /// Null means untimed.
  final int? timeLimitMinutes;
  final int passingScorePercent;

  int get totalPoints => questions.fold(0, (sum, q) => sum + q.points);
  int get questionCount => questions.length;

  Quiz copyWith({
    String? title,
    String? description,
    List<Question>? questions,
    int? timeLimitMinutes,
    int? passingScorePercent,
  }) {
    return Quiz(
      id: id,
      title: title ?? this.title,
      description: description ?? this.description,
      questions: questions ?? this.questions,
      timeLimitMinutes: timeLimitMinutes ?? this.timeLimitMinutes,
      passingScorePercent: passingScorePercent ?? this.passingScorePercent,
    );
  }
}
