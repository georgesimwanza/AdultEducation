/// Supported question types in the Quiz feature.
enum QuestionType { multipleChoice, trueFalse, shortAnswer, essay }

extension QuestionTypeLabel on QuestionType {
  String get label {
    switch (this) {
      case QuestionType.multipleChoice:
        return 'Multiple Choice';
      case QuestionType.trueFalse:
        return 'True / False';
      case QuestionType.shortAnswer:
        return 'Short Answer';
      case QuestionType.essay:
        return 'Essay';
    }
  }

  String get description {
    switch (this) {
      case QuestionType.multipleChoice:
        return 'Learner picks one correct option from a list';
      case QuestionType.trueFalse:
        return 'Learner chooses True or False';
      case QuestionType.shortAnswer:
        return 'Learner types a brief text answer, auto-graded by match';
      case QuestionType.essay:
        return 'Learner writes a longer response, manually graded';
    }
  }
}

/// Base class for every quiz question.
///
/// This is a Dart 3 sealed class with exactly 4 subclasses. Because it's
/// sealed, any `switch` over a Question (see QuestionEditorScreen) must
/// handle all 4 types or the app won't compile — so adding a 5th type
/// later can't silently be forgotten anywhere.
sealed class Question {
  const Question({
    required this.id,
    required this.text,
    this.points = 1,
    this.explanation,
  });

  final String id;
  final String text;
  final int points;
  final String? explanation;

  QuestionType get type;
}

class MultipleChoiceQuestion extends Question {
  const MultipleChoiceQuestion({
    required super.id,
    required super.text,
    required this.options,
    required this.correctOptionIndex,
    super.points,
    super.explanation,
  });

  final List<String> options;
  final int correctOptionIndex;

  @override
  QuestionType get type => QuestionType.multipleChoice;
}

class TrueFalseQuestion extends Question {
  const TrueFalseQuestion({
    required super.id,
    required super.text,
    required this.correctAnswer,
    super.points,
    super.explanation,
  });

  final bool correctAnswer;

  @override
  QuestionType get type => QuestionType.trueFalse;
}

class ShortAnswerQuestion extends Question {
  const ShortAnswerQuestion({
    required super.id,
    required super.text,
    required this.acceptedAnswers,
    this.caseSensitive = false,
    super.points,
    super.explanation,
  });

  /// Any of these strings counts as correct.
  final List<String> acceptedAnswers;
  final bool caseSensitive;

  @override
  QuestionType get type => QuestionType.shortAnswer;
}

class EssayQuestion extends Question {
  const EssayQuestion({
    required super.id,
    required super.text,
    this.minWords,
    this.maxWords,
    this.rubric,
    super.points,
    super.explanation,
  });

  final int? minWords;
  final int? maxWords;

  /// Grading guidance shown to the instructor when manually marking.
  final String? rubric;

  @override
  QuestionType get type => QuestionType.essay;
}
