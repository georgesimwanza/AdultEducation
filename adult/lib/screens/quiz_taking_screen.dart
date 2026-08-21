import 'dart:async';
import 'package:flutter/material.dart';
import 'package:adult/Model/quiz.dart';
import 'package:adult/Model/question.dart';

/// Displays the quiz interface where a student can answer questions.
///
/// Supported question types include:
/// - Multiple-choice questions.
/// - True/false questions.
/// - Short-answer questions.
/// - Essay questions.
///
/// Multiple-choice, true/false, and short-answer questions are
/// automatically graded when the quiz is submitted.
///
/// Essay questions are marked as pending because they require
/// manual grading by an instructor.
class QuizTakingScreen extends StatefulWidget {
  const QuizTakingScreen({super.key, required this.quiz});

  /// The quiz being attempted by the student.
  final Quiz quiz;

  @override
  State<QuizTakingScreen> createState() => _QuizTakingScreenState();
}

class _QuizTakingScreenState extends State<QuizTakingScreen> {
  // Form key used to validate text-based questions before submission.
  final _formKey = GlobalKey<FormState>();

  /// Stores answers selected or entered by the student.
  ///
  /// The key is the question ID.
  ///
  /// The value can be:
  /// - int for multiple-choice answers.
  /// - bool for true/false answers.
  /// - String for short-answer and essay responses.
  final Map<String, dynamic> _answers = {};

  // Stores text controllers for short-answer and essay questions.
  final Map<String, TextEditingController> _textControllers = {};

  // Timer used when the quiz has a time limit.
  Timer? _timer;

  // Number of seconds remaining before the quiz is automatically submitted.
  int? _secondsRemaining;

  // Letters displayed beside multiple-choice options.
  static const List<String> _letters = ['a', 'b', 'c', 'd', 'e', 'f', 'g', 'h'];

  @override
  void initState() {
    super.initState();

    // Retrieve the quiz time limit.
    final limit = widget.quiz.timeLimitMinutes;

    // Start the countdown only when the quiz has a valid time limit.
    if (limit != null && limit > 0) {
      _secondsRemaining = limit * 60;

      _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
        // Prevent state updates after the widget has been removed.
        if (!mounted) return;

        setState(() {
          // Reduce the remaining time by one second.
          _secondsRemaining = (_secondsRemaining ?? 0) - 1;

          // Automatically submit the quiz when the timer reaches zero.
          if (_secondsRemaining! <= 0) {
            timer.cancel();
            _submit(autoSubmitted: true);
          }
        });
      });
    }
  }

  /// Returns a text controller for a specific question.
  ///
  /// A controller is created only once for each question ID and then
  /// reused whenever the question widget rebuilds.
  TextEditingController _controllerFor(String questionId) {
    return _textControllers.putIfAbsent(
      questionId,
      () => TextEditingController(),
    );
  }

  @override
  void dispose() {
    // Stop the timer when leaving the quiz screen.
    _timer?.cancel();

    // Dispose all text controllers to prevent memory leaks.
    for (final controller in _textControllers.values) {
      controller.dispose();
    }

    super.dispose();
  }

  /// Converts a number of seconds into MM:SS format.
  ///
  /// For example:
  /// 125 seconds becomes "02:05".
  String _formatTime(int totalSeconds) {
    final seconds = totalSeconds < 0 ? 0 : totalSeconds;

    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;

    return '${minutes.toString().padLeft(2, '0')}:'
        '${remainingSeconds.toString().padLeft(2, '0')}';
  }

  /// Submits the quiz and calculates the student's score.
  ///
  /// When [autoSubmitted] is false, the form is validated before
  /// submission.
  ///
  /// Essay questions are not automatically graded and are instead
  /// marked as pending manual grading.
  void _submit({bool autoSubmitted = false}) {
    // Validate the form when the student manually submits.
    //
    // Automatic submission caused by the timer skips this validation.
    if (!autoSubmitted && !_formKey.currentState!.validate()) {
      return;
    }

    // Stop the timer because the quiz has been submitted.
    _timer?.cancel();

    // Points earned from automatically graded questions.
    int earnedPoints = 0;

    // Total points that can be automatically graded.
    int autoGradablePoints = 0;

    // Points belonging to essay questions awaiting manual grading.
    int pendingPoints = 0;

    // Stores the result of each individual question.
    final List<_QuestionResult> results = [];

    // Evaluate every question in the quiz.
    for (final question in widget.quiz.questions) {
      switch (question) {
        // Handle multiple-choice questions.
        case MultipleChoiceQuestion q:
          autoGradablePoints += q.points;

          // Retrieve the option selected by the student.
          final selected = _answers[q.id] as int?;

          // Compare the selected option with the correct option.
          final correct = selected == q.correctOptionIndex;

          // Award points when the answer is correct.
          if (correct) {
            earnedPoints += q.points;
          }

          results.add(
            _QuestionResult(question: q, correct: correct, pending: false),
          );

        // Handle true/false questions.
        case TrueFalseQuestion q:
          autoGradablePoints += q.points;

          // Retrieve the student's true/false selection.
          final selected = _answers[q.id] as bool?;

          // Compare the answer with the correct answer.
          final correct = selected == q.correctAnswer;

          if (correct) {
            earnedPoints += q.points;
          }

          results.add(
            _QuestionResult(question: q, correct: correct, pending: false),
          );

        // Handle short-answer questions.
        case ShortAnswerQuestion q:
          autoGradablePoints += q.points;

          // Remove unnecessary whitespace from the student's answer.
          final raw = (_answers[q.id] as String? ?? '').trim();

          // Check whether the answer matches one of the accepted answers.
          final correct = q.acceptedAnswers.any((accepted) {
            return q.caseSensitive
                ? accepted.trim() == raw
                : accepted.trim().toLowerCase() == raw.toLowerCase();
          });

          if (correct) {
            earnedPoints += q.points;
          }

          results.add(
            _QuestionResult(question: q, correct: correct, pending: false),
          );

        // Essay questions require manual grading.
        case EssayQuestion q:
          pendingPoints += q.points;

          results.add(
            _QuestionResult(question: q, correct: null, pending: true),
          );
      }
    }

    // Only automatically gradable questions are included in the
    // percentage calculation.
    final totalGradablePoints = autoGradablePoints;

    final percent = totalGradablePoints == 0
        ? 0
        : ((earnedPoints / totalGradablePoints) * 100).round();

    // Determine whether the student passed based on the quiz
    // passing percentage.
    final passed = percent >= widget.quiz.passingScorePercent;

    // Replace the quiz screen with the results screen.
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => _QuizResultsScreen(
          earnedPoints: earnedPoints,
          totalGradablePoints: totalGradablePoints,
          pendingPoints: pendingPoints,
          percent: percent,
          passed: passed,
          passingScorePercent: widget.quiz.passingScorePercent,
          results: results,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,

      // App bar displays the quiz title and remaining time.
      appBar: AppBar(
        title: Text(widget.quiz.title, overflow: TextOverflow.ellipsis),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          // Display the timer only when the quiz has a time limit.
          if (_secondsRemaining != null)
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF262626),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.white24),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.timer_outlined,
                        size: 15,
                        color: Colors.white,
                      ),

                      const SizedBox(width: 6),

                      Text(
                        _formatTime(_secondsRemaining!),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),

      // Form wraps the questions so that text-based questions
      // can be validated before submission.
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
          children: [
            // Display the quiz description when one is available.
            if (widget.quiz.description.isNotEmpty) ...[
              Text(
                widget.quiz.description,
                style: const TextStyle(color: Colors.grey),
              ),

              const SizedBox(height: 16),
            ],

            // Build a card for every question in the quiz.
            for (int i = 0; i < widget.quiz.questions.length; i++)
              _buildQuestionCard(i, widget.quiz.questions[i]),
          ],
        ),
      ),

      // Submit button remains visible at the bottom of the screen.
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),

              // Submit the quiz manually.
              onPressed: () => _submit(),

              child: const Text(
                'Submit Quiz',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Builds the visual card for an individual quiz question.
  Widget _buildQuestionCard(int index, Question question) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F7F7),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Question number and point value.
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Question ${index + 1}/'
                '${widget.quiz.questions.length}',
                style: const TextStyle(
                  color: Colors.black,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),

              Text(
                '${question.points} pt'
                '${question.points == 1 ? '' : 's'}',
                style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
              ),
            ],
          ),

          const SizedBox(height: 10),

          // Display the question text.
          Text(
            question.text,
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15.5),
          ),

          const SizedBox(height: 14),

          // Display the appropriate answer control based
          // on the question type.
          _buildAnswerInput(question),
        ],
      ),
    );
  }

  /// Builds the answer input appropriate for the question type.
  Widget _buildAnswerInput(Question question) {
    return switch (question) {
      // Multiple-choice questions display selectable options.
      MultipleChoiceQuestion q => Column(
        children: [
          for (int i = 0; i < q.options.length; i++)
            _letterOptionTile(
              letter: _letters[i],
              label: q.options[i],
              selected: _answers[q.id] == i,
              onTap: () {
                setState(() {
                  _answers[q.id] = i;
                });
              },
            ),
        ],
      ),

      // True/false questions provide two selectable options.
      TrueFalseQuestion q => Column(
        children: [
          _letterOptionTile(
            letter: 'a',
            label: 'True',
            selected: _answers[q.id] == true,
            onTap: () {
              setState(() {
                _answers[q.id] = true;
              });
            },
          ),

          _letterOptionTile(
            letter: 'b',
            label: 'False',
            selected: _answers[q.id] == false,
            onTap: () {
              setState(() {
                _answers[q.id] = false;
              });
            },
          ),
        ],
      ),

      // Short-answer questions use a single-line text field.
      ShortAnswerQuestion q => TextFormField(
        controller: _controllerFor(q.id),
        decoration: _fieldDecoration('Your answer'),
        validator: (v) =>
            (v == null || v.trim().isEmpty) ? 'Please answer' : null,
        onChanged: (v) {
          _answers[q.id] = v;
        },
      ),

      // Essay questions use a multi-line text field.
      EssayQuestion q => TextFormField(
        controller: _controllerFor(q.id),
        maxLines: 5,
        decoration: _fieldDecoration(
          'Your response',
          hint: 'This question is manually graded by an instructor',
        ),
        validator: (v) =>
            (v == null || v.trim().isEmpty) ? 'Please answer' : null,
        onChanged: (v) {
          _answers[q.id] = v;
        },
      ),
    };
  }

  /// Creates the common styling used by text input fields.
  InputDecoration _fieldDecoration(String label, {String? hint}) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFDDDDDD)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.black, width: 1.6),
      ),
    );
  }

  /// Builds a selectable option tile used by multiple-choice
  /// and true/false questions.
  Widget _letterOptionTile({
    required String letter,
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: selected ? Colors.black : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected ? Colors.black : const Color(0xFFDDDDDD),
            ),
          ),
          child: Row(
            children: [
              // Circular letter indicator.
              Container(
                width: 26,
                height: 26,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: selected ? Colors.white : const Color(0xFFF0F0F0),
                  shape: BoxShape.circle,
                ),
                child: Text(
                  letter,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: selected ? Colors.black : Colors.black87,
                  ),
                ),
              ),

              const SizedBox(width: 12),

              // Answer text.
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: selected ? Colors.white : Colors.black87,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Stores the result of an individual quiz question.
///
/// [correct] is null when the question is awaiting manual grading.
class _QuestionResult {
  const _QuestionResult({
    required this.question,
    required this.correct,
    required this.pending,
  });

  final Question question;

  /// Whether the answer was correct.
  ///
  /// A null value means the question has not been graded yet.
  final bool? correct;

  /// Indicates whether the question requires manual grading.
  final bool pending;
}

/// Displays the results after a quiz has been submitted.
///
/// This screen shows the student's score, pass/fail status,
/// pending essay points, and a breakdown of each question.
class _QuizResultsScreen extends StatelessWidget {
  const _QuizResultsScreen({
    required this.earnedPoints,
    required this.totalGradablePoints,
    required this.pendingPoints,
    required this.percent,
    required this.passed,
    required this.passingScorePercent,
    required this.results,
  });

  final int earnedPoints;
  final int totalGradablePoints;
  final int pendingPoints;
  final int percent;
  final bool passed;
  final int passingScorePercent;
  final List<_QuestionResult> results;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
                child: Column(
                  children: [
                    // Displays a trophy when the student passes
                    // and a flag when they do not.
                    Container(
                      width: 160,
                      height: 160,
                      decoration: const BoxDecoration(
                        color: Color(0xFFF0F0F0),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        passed
                            ? Icons.emoji_events_rounded
                            : Icons.flag_rounded,
                        size: 72,
                        color: Colors.black,
                      ),
                    ),

                    const SizedBox(height: 28),

                    const Text(
                      'Your Score',
                      style: TextStyle(color: Colors.black54, fontSize: 14),
                    ),

                    const SizedBox(height: 4),

                    // Display points earned out of automatically gradable points.
                    Text(
                      '$earnedPoints/$totalGradablePoints',
                      style: const TextStyle(
                        color: Colors.black,
                        fontSize: 30,
                        fontWeight: FontWeight.w800,
                      ),
                    ),

                    const SizedBox(height: 10),

                    // Display the appropriate message based on the result.
                    Text(
                      passed ? 'Congratulations!' : 'Keep Practicing!',
                      style: const TextStyle(
                        color: Colors.black,
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                      ),
                    ),

                    const SizedBox(height: 6),

                    Text(
                      passed
                          ? 'Great job! You have done well'
                          : 'You needed $passingScorePercent% '
                                'to pass — review and try again',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.black54,
                        fontSize: 13,
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Displays the calculated percentage score.
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF0F0F0),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '$percent% Score',
                        style: const TextStyle(
                          color: Colors.black,
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),

                    // Display pending essay points when applicable.
                    if (pendingPoints > 0) ...[
                      const SizedBox(height: 10),

                      Text(
                        '$pendingPoints point(s) pending '
                        'manual grading (essay).',
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 12,
                        ),
                      ),
                    ],

                    const SizedBox(height: 28),

                    // Heading for the question-by-question results.
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Question breakdown',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                          color: Colors.grey.shade700,
                        ),
                      ),
                    ),

                    const SizedBox(height: 8),

                    // Display the result of every question.
                    for (int i = 0; i < results.length; i++)
                      Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF7F7F7),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            // Select the icon based on the question result.
                            Icon(
                              results[i].pending
                                  ? Icons.hourglass_empty
                                  : (results[i].correct == true
                                        ? Icons.check_circle
                                        : Icons.cancel),
                              size: 18,
                              color: results[i].pending
                                  ? Colors.grey
                                  : Colors.black,
                            ),

                            const SizedBox(width: 10),

                            // Display the question text.
                            Expanded(
                              child: Text(
                                'Q${i + 1}: '
                                '${results[i].question.text}',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontSize: 13),
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ),

            // Button that returns the user to the first route,
            // normally the application's home screen.
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  onPressed: () {
                    Navigator.of(context).popUntil((route) => route.isFirst);
                  },
                  child: const Text(
                    'Back to Home',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
