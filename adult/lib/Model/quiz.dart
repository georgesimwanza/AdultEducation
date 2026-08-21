import 'question.dart';

/// A quiz is metadata plus an ordered list of mixed-type questions.
/// Because [Question] is sealed, [questions] can freely combine Multiple
/// Choice, True/False, Short Answer, and Essay questions in any order.
class Quiz {
  const Quiz({
    required this.id,
    required this.title,
    required this.subjectId,
    required this.institutionId,
    required this.programmeId,
    this.description = '',
    this.questions = const [],
    this.timeLimitMinutes,
    this.passingScorePercent = 50,
  });
  final String id;
  final String title;
  final String description;

  /// FK to the subject this quiz belongs to.
  final int subjectId;

  /// FK to the institution this quiz belongs to.
  final int institutionId;

  /// FK to the programme this quiz belongs to.
  final int programmeId;
  final List<Question> questions;

  /// Null means untimed.
  final int? timeLimitMinutes;
  final int passingScorePercent;
  int get totalPoints => questions.fold(0, (sum, q) => sum + q.points);
  int get questionCount => questions.length;
  Quiz copyWith({
    String? title,
    String? description,
    int? subjectId,
    int? institutionId,
    int? programmeId,
    List<Question>? questions,
    int? timeLimitMinutes,
    int? passingScorePercent,
  }) {
    return Quiz(
      id: id,
      title: title ?? this.title,
      description: description ?? this.description,
      subjectId: subjectId ?? this.subjectId,
      institutionId: institutionId ?? this.institutionId,
      programmeId: programmeId ?? this.programmeId,
      questions: questions ?? this.questions,
      timeLimitMinutes: timeLimitMinutes ?? this.timeLimitMinutes,
      passingScorePercent: passingScorePercent ?? this.passingScorePercent,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'description': description,
    'courseId': subjectId,
    'institutionId': institutionId,
    'programmeId': programmeId,
    'questions': questions.map((q) => q.toJson()).toList(),
    'timeLimitMinutes': timeLimitMinutes,
    'passingScorePercent': passingScorePercent,
  };
  factory Quiz.fromJson(Map<String, dynamic> json) {
    return Quiz(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String? ?? '',
      subjectId: json['courseId'] as int,
      institutionId: json['institutionId'] as int,
      programmeId: json['programmeId'] as int,
      questions: (json['questions'] as List? ?? [])
          .map((q) => Question.fromJson(q as Map<String, dynamic>))
          .toList(),
      timeLimitMinutes: json['timeLimitMinutes'] as int?,
      passingScorePercent: json['passingScorePercent'] as int? ?? 50,
    );
  }
}
