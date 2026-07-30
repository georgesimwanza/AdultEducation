import 'dart:async';
import 'package:flutter/material.dart';
import 'package:adult/Model/quiz.dart';
import 'package:adult/Model/question.dart';

/// Lets a student answer every question in a scrollable quiz, then shows
/// a full-screen celebratory result. Multiple choice, true/false, and
/// short answer are auto-graded; essay questions are flagged as pending
/// manual grading and don't count toward the auto-score.
class QuizTakingScreen extends StatefulWidget {
  const QuizTakingScreen({super.key, required this.quiz});
  final Quiz quiz;

  @override
  State<QuizTakingScreen> createState() => _QuizTakingScreenState();
}

class _QuizTakingScreenState extends State<QuizTakingScreen> {
  final _formKey = GlobalKey<FormState>();

  // question.id -> answer. int for MCQ index, bool for true/false,
  // String for short answer / essay text.
  final Map<String, dynamic> _answers = {};
  final Map<String, TextEditingController> _textControllers = {};

  Timer? _timer;
  int? _secondsRemaining;

  static const List<String> _letters = ['a', 'b', 'c', 'd', 'e', 'f', 'g', 'h'];

  @override
  void initState() {
    super.initState();
    final limit = widget.quiz.timeLimitMinutes;
    if (limit != null && limit > 0) {
      _secondsRemaining = limit * 60;
      _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (!mounted) return;
        setState(() {
          _secondsRemaining = (_secondsRemaining ?? 0) - 1;
          if (_secondsRemaining! <= 0) {
            timer.cancel();
            _submit(autoSubmitted: true);
          }
        });
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
    for (final c in _textControllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  String _formatTime(int totalSeconds) {
    final s = totalSeconds < 0 ? 0 : totalSeconds;
    final m = s ~/ 60;
    final sec = s % 60;
    return '${m.toString().padLeft(2, '0')}:${sec.toString().padLeft(2, '0')}';
  }

  void _submit({bool autoSubmitted = false}) {
    if (!autoSubmitted && !_formKey.currentState!.validate()) return;
    _timer?.cancel();

    int earnedPoints = 0;
    int autoGradablePoints = 0;
    int pendingPoints = 0;
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
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(widget.quiz.title, overflow: TextOverflow.ellipsis),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
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
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
          children: [
            if (widget.quiz.description.isNotEmpty) ...[
              Text(
                widget.quiz.description,
                style: const TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 16),
            ],
            for (int i = 0; i < widget.quiz.questions.length; i++)
              _buildQuestionCard(i, widget.quiz.questions[i]),
          ],
        ),
      ),
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Question ${index + 1}/${widget.quiz.questions.length}',
                style: const TextStyle(
                  color: Colors.black,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                '${question.points} pt${question.points == 1 ? '' : 's'}',
                style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            question.text,
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15.5),
          ),
          const SizedBox(height: 14),
          _buildAnswerInput(question),
        ],
      ),
    );
  }

  Widget _buildAnswerInput(Question question) {
    return switch (question) {
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
      TrueFalseQuestion q => Column(
        children: [
          _letterOptionTile(
            letter: 'a',
            label: 'True',
            selected: _answers[q.id] == true,
            onTap: () => setState(() => _answers[q.id] = true),
          ),
          _letterOptionTile(
            letter: 'b',
            label: 'False',
            selected: _answers[q.id] == false,
            onTap: () => setState(() => _answers[q.id] = false),
          ),
        ],
      ),
      ShortAnswerQuestion q => TextFormField(
        controller: _controllerFor(q.id),
        decoration: _fieldDecoration('Your answer'),
        validator: (v) =>
            (v == null || v.trim().isEmpty) ? 'Please answer' : null,
        onChanged: (v) => _answers[q.id] = v,
      ),
      EssayQuestion q => TextFormField(
        controller: _controllerFor(q.id),
        maxLines: 5,
        decoration: _fieldDecoration(
          'Your response',
          hint: 'This question is manually graded by an instructor',
        ),
        validator: (v) =>
            (v == null || v.trim().isEmpty) ? 'Please answer' : null,
        onChanged: (v) => _answers[q.id] = v,
      ),
    };
  }

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

class _QuestionResult {
  const _QuestionResult({
    required this.question,
    required this.correct,
    required this.pending,
  });
  final Question question;
  final bool? correct; // null when pending
  final bool pending;
}

/// Full-screen celebratory result, replacing the old popup dialog —
/// matches the mockup's "Congratulations" screen.
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
                    Text(
                      '$earnedPoints/$totalGradablePoints',
                      style: const TextStyle(
                        color: Colors.black,
                        fontSize: 30,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 10),
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
                          : 'You needed $passingScorePercent% to pass — review and try again',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.black54,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 16),
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
                    if (pendingPoints > 0) ...[
                      const SizedBox(height: 10),
                      Text(
                        '$pendingPoints point(s) pending manual grading (essay).',
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 12,
                        ),
                      ),
                    ],
                    const SizedBox(height: 28),
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
                            Expanded(
                              child: Text(
                                'Q${i + 1}: ${results[i].question.text}',
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
                  onPressed: () =>
                      Navigator.of(context).popUntil((route) => route.isFirst),
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
