import 'dart:async';
import 'package:flutter/material.dart';
import 'package:adult/Model/quiz.dart';
import 'package:adult/Model/question.dart';
import 'package:adult/screens/color.dart';

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

  /// Answers selected or entered by the student, keyed by question ID.
  ///
  /// The value can be:
  /// - int for multiple-choice answers.
  /// - bool for true/false answers.
  /// - String for short-answer and essay responses.
  final Map<String, dynamic> _answers = {};

  // Text controllers for short-answer and essay questions.
  final Map<String, TextEditingController> _textControllers = {};

  // Timer used when the quiz has a time limit.
  Timer? _timer;

  // Seconds remaining before the quiz is automatically submitted.
  int? _secondsRemaining;

  // Guards against submitting twice (e.g. timer fires as user taps Submit).
  bool _submitted = false;

  // Letters displayed beside multiple-choice options.
  static const List<String> _letters = ['A', 'B', 'C', 'D', 'E', 'F', 'G', 'H'];

  @override
  void initState() {
    super.initState();

    final limit = widget.quiz.timeLimitMinutes;

    // Start the countdown only when the quiz has a valid time limit.
    if (limit != null && limit > 0) {
      _secondsRemaining = limit * 60;

      _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (!mounted) return;

        setState(() {
          _secondsRemaining = (_secondsRemaining ?? 0) - 1;
        });

        // Submit AFTER the state update — navigating from inside
        // setState() can throw.
        if ((_secondsRemaining ?? 0) <= 0) {
          timer.cancel();
          _submit(autoSubmitted: true);
        }
      });
    }
  }

  TextEditingController _controllerFor(String questionId) {
    return _textControllers.putIfAbsent(
      questionId,
          () => TextEditingController(),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    for (final controller in _textControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  /// Converts a number of seconds into MM:SS format.
  String _formatTime(int totalSeconds) {
    final seconds = totalSeconds < 0 ? 0 : totalSeconds;
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:'
        '${remainingSeconds.toString().padLeft(2, '0')}';
  }

  bool _isAnswered(String questionId) {
    final v = _answers[questionId];
    if (v == null) return false;
    if (v is String) return v.trim().isNotEmpty;
    return true;
  }

  int get _answeredCount =>
      widget.quiz.questions.where((q) => _isAnswered(q.id)).length;

  // ── Dialogs ────────────────────────────────────────────────────────────

  Future<bool> _confirm({
    required String title,
    required String message,
    required String confirmLabel,
    bool destructive = false,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: EduColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 18,
            color: EduColors.textPrimary,
          ),
        ),
        content: Text(
          message,
          style: const TextStyle(
            fontSize: 14,
            height: 1.4,
            color: EduColors.textSecondary,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text(
              'Keep going',
              style: TextStyle(
                color: EduColors.textSecondary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor:
              destructive ? EduColors.danger : EduColors.primary,
              foregroundColor: EduColors.onPrimary,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: Text(confirmLabel),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  Future<void> _onBackPressed() async {
    final leave = await _confirm(
      title: 'Leave this quiz?',
      message: 'Your answers so far will be lost.',
      confirmLabel: 'Leave',
      destructive: true,
    );
    if (leave && mounted) {
      _timer?.cancel();
      Navigator.pop(context);
    }
  }

  Future<void> _onSubmitPressed() async {
    // Validate text answers first so the user sees the errors.
    if (!_formKey.currentState!.validate()) return;

    final total = widget.quiz.questions.length;
    final unanswered = total - _answeredCount;
    if (unanswered > 0) {
      final go = await _confirm(
        title: 'Submit with $unanswered unanswered?',
        message:
        'You haven\'t answered $unanswered question${unanswered == 1 ? '' : 's'}. '
            'Unanswered questions score zero.',
        confirmLabel: 'Submit anyway',
      );
      if (!go) return;
    }
    _submit();
  }

  /// Submits the quiz and calculates the student's score.
  ///
  /// Essay questions are not automatically graded and are instead
  /// marked as pending manual grading.
  void _submit({bool autoSubmitted = false}) {
    if (_submitted) return;
    _submitted = true;

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

    for (final question in widget.quiz.questions) {
      switch (question) {
        case MultipleChoiceQuestion q:
          autoGradablePoints += q.points;
          final selected = _answers[q.id] as int?;
          final correct = selected == q.correctOptionIndex;
          if (correct) earnedPoints += q.points;
          results.add(
            _QuestionResult(question: q, correct: correct, pending: false),
          );

        case TrueFalseQuestion q:
          autoGradablePoints += q.points;
          final selected = _answers[q.id] as bool?;
          final correct = selected == q.correctAnswer;
          if (correct) earnedPoints += q.points;
          results.add(
            _QuestionResult(question: q, correct: correct, pending: false),
          );

        case ShortAnswerQuestion q:
          autoGradablePoints += q.points;
          final raw = (_answers[q.id] as String? ?? '').trim();
          final correct = q.acceptedAnswers.any((accepted) {
            return q.caseSensitive
                ? accepted.trim() == raw
                : accepted.trim().toLowerCase() == raw.toLowerCase();
          });
          if (correct) earnedPoints += q.points;
          results.add(
            _QuestionResult(question: q, correct: correct, pending: false),
          );

        case EssayQuestion q:
          pendingPoints += q.points;
          results.add(
            _QuestionResult(question: q, correct: null, pending: true),
          );
      }
    }

    // Only automatically gradable questions count towards the percentage.
    final totalGradablePoints = autoGradablePoints;

    final percent = totalGradablePoints == 0
        ? 0
        : ((earnedPoints / totalGradablePoints) * 100).round();

    final passed = percent >= widget.quiz.passingScorePercent;

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
          autoSubmitted: autoSubmitted,
        ),
      ),
    );
  }

  // ── Build ──────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final total = widget.quiz.questions.length;

    return Scaffold(
      backgroundColor: EduColors.background,
      body: SafeArea(
        child: Column(
          children: [
            _buildTopBar(total),
            Expanded(
              child: Form(
                key: _formKey,
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                  children: [
                    if (widget.quiz.description.isNotEmpty) ...[
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: EduColors.primarySoft,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(Icons.info_outline_rounded,
                                size: 18, color: EduColors.primary),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                widget.quiz.description,
                                style: const TextStyle(
                                  color: EduColors.primary,
                                  fontSize: 13,
                                  height: 1.4,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),
                    ],
                    for (int i = 0; i < total; i++)
                      _buildQuestionCard(i, widget.quiz.questions[i]),
                  ],
                ),
              ),
            ),
            _buildSubmitBar(),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar(int total) {
    final answered = _answeredCount;
    final lowTime = _secondsRemaining != null && _secondsRemaining! <= 60;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: Column(
        children: [
          Row(
            children: [
              GestureDetector(
                onTap: _onBackPressed,
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: EduColors.surface,
                    shape: BoxShape.circle,
                    border: Border.all(color: EduColors.border),
                  ),
                  child: const Icon(Icons.close_rounded,
                      color: EduColors.textPrimary, size: 20),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.quiz.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: EduColors.textPrimary,
                      ),
                    ),
                    Text(
                      '$total question${total == 1 ? '' : 's'}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: EduColors.textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              if (_secondsRemaining != null)
                AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: lowTime
                        ? const Color(0xFFFDECEC)
                        : EduColors.primarySoft,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.timer_outlined,
                        size: 16,
                        color: lowTime ? EduColors.danger : EduColors.primary,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        _formatTime(_secondsRemaining!),
                        style: TextStyle(
                          color:
                          lowTime ? EduColors.danger : EduColors.primary,
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: TweenAnimationBuilder<double>(
                  tween: Tween(
                      begin: 0, end: total == 0 ? 0 : answered / total),
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeOut,
                  builder: (context, v, _) => ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: v,
                      minHeight: 6,
                      color: EduColors.primary,
                      backgroundColor: EduColors.primarySoft,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                '$answered/$total answered',
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: EduColors.textSecondary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSubmitBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      decoration: const BoxDecoration(
        color: EduColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: Color(0x143D5CFF),
            blurRadius: 20,
            offset: Offset(0, -6),
          ),
        ],
      ),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: EduColors.primary,
            foregroundColor: EduColors.onPrimary,
            elevation: 0,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(28),
            ),
          ),
          onPressed: _onSubmitPressed,
          child: const Text(
            'Submit Quiz',
            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
          ),
        ),
      ),
    );
  }

  /// Builds the visual card for an individual quiz question.
  Widget _buildQuestionCard(int index, Question question) {
    final answered = _isAnswered(question.id);

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: EduColors.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: answered ? EduColors.primarySoft : EduColors.border,
          width: answered ? 1.5 : 1,
        ),
        boxShadow: EduColors.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: EduColors.primarySoft,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'Question ${index + 1} of ${widget.quiz.questions.length}',
                  style: const TextStyle(
                    color: EduColors.primary,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              Container(
                padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: EduColors.accentSoft,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${question.points} pt${question.points == 1 ? '' : 's'}',
                  style: const TextStyle(
                    color: EduColors.accent,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            question.text,
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 15.5,
              height: 1.35,
              color: EduColors.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
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
              onTap: () => setState(() => _answers[q.id] = i),
            ),
        ],
      ),

    // True/false questions provide two selectable options.
      TrueFalseQuestion q => Column(
        children: [
          _letterOptionTile(
            letter: 'A',
            label: 'True',
            selected: _answers[q.id] == true,
            onTap: () => setState(() => _answers[q.id] = true),
          ),
          _letterOptionTile(
            letter: 'B',
            label: 'False',
            selected: _answers[q.id] == false,
            onTap: () => setState(() => _answers[q.id] = false),
          ),
        ],
      ),

    // Short-answer questions use a single-line text field.
      ShortAnswerQuestion q => TextFormField(
        controller: _controllerFor(q.id),
        cursorColor: EduColors.primary,
        style: const TextStyle(color: EduColors.textPrimary),
        decoration: _fieldDecoration('Your answer'),
        validator: (v) =>
        (v == null || v.trim().isEmpty) ? 'Please answer' : null,
        onChanged: (v) => _onTextChanged(q.id, v),
      ),

    // Essay questions use a multi-line text field.
      EssayQuestion q => TextFormField(
        controller: _controllerFor(q.id),
        maxLines: 5,
        cursorColor: EduColors.primary,
        style: const TextStyle(color: EduColors.textPrimary),
        decoration: _fieldDecoration(
          'Your response',
          hint: 'This question is manually graded by an instructor',
        ),
        validator: (v) =>
        (v == null || v.trim().isEmpty) ? 'Please answer' : null,
        onChanged: (v) => _onTextChanged(q.id, v),
      ),
    };
  }

  /// Stores text answers; only rebuilds when answered/unanswered flips,
  /// so typing doesn't rebuild the whole list on every keystroke.
  void _onTextChanged(String id, String v) {
    final was = _isAnswered(id);
    _answers[id] = v;
    if (was != _isAnswered(id)) setState(() {});
  }

  InputDecoration _fieldDecoration(String label, {String? hint}) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      hintStyle: const TextStyle(
        color: EduColors.textSecondary,
        fontSize: 12,
      ),
      labelStyle: const TextStyle(color: EduColors.textSecondary),
      floatingLabelStyle: const TextStyle(color: EduColors.primary),
      filled: true,
      fillColor: EduColors.background,
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: EduColors.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: EduColors.primary, width: 1.6),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: EduColors.danger),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: EduColors.danger, width: 1.6),
      ),
    );
  }

  /// Selectable option tile used by multiple-choice and true/false questions.
  Widget _letterOptionTile({
    required String letter,
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: selected ? EduColors.primarySoft : EduColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: selected ? EduColors.primary : EduColors.border,
              width: selected ? 1.6 : 1,
            ),
          ),
          child: Row(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                width: 30,
                height: 30,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: selected ? EduColors.primary : EduColors.background,
                  shape: BoxShape.circle,
                ),
                child: selected
                    ? const Icon(Icons.check_rounded,
                    size: 16, color: EduColors.onPrimary)
                    : Text(
                  letter,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: EduColors.textSecondary,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color:
                    selected ? EduColors.primary : EduColors.textPrimary,
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

  /// Whether the answer was correct. Null = not graded yet.
  final bool? correct;

  /// Indicates whether the question requires manual grading.
  final bool pending;
}

/// Displays the results after a quiz has been submitted.
///
/// Shows the student's score, pass/fail status, pending essay points,
/// and a breakdown of each question.
class _QuizResultsScreen extends StatelessWidget {
  const _QuizResultsScreen({
    required this.earnedPoints,
    required this.totalGradablePoints,
    required this.pendingPoints,
    required this.percent,
    required this.passed,
    required this.passingScorePercent,
    required this.results,
    this.autoSubmitted = false,
  });

  final int earnedPoints;
  final int totalGradablePoints;
  final int pendingPoints;
  final int percent;
  final bool passed;
  final int passingScorePercent;
  final List<_QuestionResult> results;
  final bool autoSubmitted;

  @override
  Widget build(BuildContext context) {
    final ringColor = passed ? EduColors.success : EduColors.accent;
    final ringSoft = passed ? EduColors.successSoft : EduColors.accentSoft;

    return Scaffold(
      backgroundColor: EduColors.background,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 28, 20, 16),
                child: Column(
                  children: [
                    // Animated score ring with trophy / flag inside.
                    SizedBox(
                      width: 180,
                      height: 180,
                      child: TweenAnimationBuilder<double>(
                        tween: Tween(begin: 0, end: percent / 100),
                        duration: const Duration(milliseconds: 1000),
                        curve: Curves.easeOutCubic,
                        builder: (context, v, _) => Stack(
                          alignment: Alignment.center,
                          children: [
                            SizedBox(
                              width: 180,
                              height: 180,
                              child: CircularProgressIndicator(
                                value: v,
                                strokeWidth: 10,
                                color: ringColor,
                                backgroundColor: ringSoft,
                              ),
                            ),
                            Container(
                              width: 136,
                              height: 136,
                              decoration: BoxDecoration(
                                color: ringSoft,
                                shape: BoxShape.circle,
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    passed
                                        ? Icons.emoji_events_rounded
                                        : Icons.flag_rounded,
                                    size: 40,
                                    color: ringColor,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${(v * 100).round()}%',
                                    style: TextStyle(
                                      color: ringColor,
                                      fontSize: 26,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      passed ? 'Congratulations!' : 'Keep Practicing!',
                      style: const TextStyle(
                        color: EduColors.textPrimary,
                        fontSize: 24,
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
                        color: EduColors.textSecondary,
                        fontSize: 13,
                        height: 1.4,
                      ),
                    ),
                    if (autoSubmitted) ...[
                      const SizedBox(height: 10),
                      const Text(
                        "Time's up — your quiz was submitted automatically.",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: EduColors.danger,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                    const SizedBox(height: 18),

                    // Score summary cards.
                    Row(
                      children: [
                        Expanded(
                          child: _summaryCard(
                            label: 'Your score',
                            value: '$earnedPoints/$totalGradablePoints',
                            icon: Icons.stars_rounded,
                            fg: EduColors.primary,
                            bg: EduColors.primarySoft,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _summaryCard(
                            label: 'Pass mark',
                            value: '$passingScorePercent%',
                            icon: Icons.flag_rounded,
                            fg: EduColors.accent,
                            bg: EduColors.accentSoft,
                          ),
                        ),
                      ],
                    ),

                    if (pendingPoints > 0) ...[
                      const SizedBox(height: 12),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: EduColors.accentSoft,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.hourglass_top_rounded,
                                size: 18, color: EduColors.accent),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                '$pendingPoints point(s) pending '
                                    'manual grading (essay).',
                                style: const TextStyle(
                                  color: EduColors.accent,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

                    const SizedBox(height: 26),
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Question breakdown',
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 16,
                          color: EduColors.textPrimary,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    for (int i = 0; i < results.length; i++)
                      _buildResultRow(i, results[i]),
                  ],
                ),
              ),
            ),

            // Returns the user to the first route (normally the home screen).
            Container(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
              decoration: const BoxDecoration(
                color: EduColors.surface,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                boxShadow: [
                  BoxShadow(
                    color: Color(0x143D5CFF),
                    blurRadius: 20,
                    offset: Offset(0, -6),
                  ),
                ],
              ),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: EduColors.primary,
                    foregroundColor: EduColors.onPrimary,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(28),
                    ),
                  ),
                  onPressed: () {
                    Navigator.of(context).popUntil((route) => route.isFirst);
                  },
                  child: const Text(
                    'Back to Home',
                    style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _summaryCard({
    required String label,
    required String value,
    required IconData icon,
    required Color fg,
    required Color bg,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: EduColors.surface,
        borderRadius: BorderRadius.circular(18),
        boxShadow: EduColors.cardShadow,
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, size: 20, color: fg),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: EduColors.textPrimary,
                  ),
                ),
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 11,
                    color: EduColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResultRow(int i, _QuestionResult r) {
    final IconData icon;
    final Color fg;
    final Color bg;
    final String status;

    if (r.pending) {
      icon = Icons.hourglass_top_rounded;
      fg = EduColors.accent;
      bg = EduColors.accentSoft;
      status = 'Pending';
    } else if (r.correct == true) {
      icon = Icons.check_rounded;
      fg = EduColors.success;
      bg = EduColors.successSoft;
      status = 'Correct';
    } else {
      icon = Icons.close_rounded;
      fg = EduColors.danger;
      bg = const Color(0xFFFDECEC);
      status = 'Incorrect';
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: EduColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: EduColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(11),
            ),
            child: Icon(icon, size: 20, color: fg),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Q${i + 1}: ${r.question.text}',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 13,
                height: 1.3,
                fontWeight: FontWeight.w600,
                color: EduColors.textPrimary,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              status,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w800,
                color: fg,
              ),
            ),
          ),
        ],
      ),
    );
  }
}