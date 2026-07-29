import 'package:flutter/material.dart';
import 'package:adult/Model/quiz.dart';
import 'package:adult/Model/question.dart';

/// Lets a student answer every question in a quiz, then shows a
/// client-side scored result. Multiple choice, true/false, and short
/// answer are auto-graded; essay questions are flagged as pending
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

  TextEditingController _controllerFor(String questionId) {
    return _textControllers.putIfAbsent(
      questionId,
      () => TextEditingController(),
    );
  }

  @override
  void dispose() {
    for (final c in _textControllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

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

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => _ResultsDialog(
        earnedPoints: earnedPoints,
        totalGradablePoints: totalGradablePoints,
        pendingPoints: pendingPoints,
        percent: percent,
        passed: passed,
        passingScorePercent: widget.quiz.passingScorePercent,
        results: results,
        onClose: () {
          Navigator.pop(context); // close dialog
          Navigator.pop(context); // back out of the quiz
        },
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
              ),
              onPressed: _submit,
              child: const Text('Submit Quiz'),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildQuestionCard(int index, Question question) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: const BorderSide(color: Color(0xFFD6D6D6)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Question ${index + 1} · ${question.points} pt${question.points == 1 ? '' : 's'}',
              style: const TextStyle(color: Colors.grey, fontSize: 12),
            ),
            const SizedBox(height: 6),
            Text(
              question.text,
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
            ),
            const SizedBox(height: 12),
            _buildAnswerInput(question),
          ],
        ),
      ),
    );
  }

  Widget _buildAnswerInput(Question question) {
    return switch (question) {
      MultipleChoiceQuestion q => Column(
        children: [
          for (int i = 0; i < q.options.length; i++)
            RadioListTile<int>(
              contentPadding: EdgeInsets.zero,
              activeColor: Colors.black,
              value: i,
              groupValue: _answers[q.id] as int?,
              title: Text(q.options[i]),
              onChanged: (v) => setState(() => _answers[q.id] = v),
            ),
        ],
      ),
      TrueFalseQuestion q => Row(
        children: [
          Expanded(
            child: RadioListTile<bool>(
              contentPadding: EdgeInsets.zero,
              activeColor: Colors.black,
              value: true,
              groupValue: _answers[q.id] as bool?,
              title: const Text('True'),
              onChanged: (v) => setState(() => _answers[q.id] = v),
            ),
          ),
          Expanded(
            child: RadioListTile<bool>(
              contentPadding: EdgeInsets.zero,
              activeColor: Colors.black,
              value: false,
              groupValue: _answers[q.id] as bool?,
              title: const Text('False'),
              onChanged: (v) => setState(() => _answers[q.id] = v),
            ),
          ),
        ],
      ),
      ShortAnswerQuestion q => TextFormField(
        controller: _controllerFor(q.id),
        decoration: const InputDecoration(labelText: 'Your answer'),
        validator: (v) =>
            (v == null || v.trim().isEmpty) ? 'Please answer' : null,
        onChanged: (v) => _answers[q.id] = v,
      ),
      EssayQuestion q => TextFormField(
        controller: _controllerFor(q.id),
        maxLines: 5,
        decoration: const InputDecoration(
          labelText: 'Your response',
          hintText: 'This question is manually graded by an instructor',
        ),
        validator: (v) =>
            (v == null || v.trim().isEmpty) ? 'Please answer' : null,
        onChanged: (v) => _answers[q.id] = v,
      ),
    };
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

class _ResultsDialog extends StatelessWidget {
  const _ResultsDialog({
    required this.earnedPoints,
    required this.totalGradablePoints,
    required this.pendingPoints,
    required this.percent,
    required this.passed,
    required this.passingScorePercent,
    required this.results,
    required this.onClose,
  });

  final int earnedPoints;
  final int totalGradablePoints;
  final int pendingPoints;
  final int percent;
  final bool passed;
  final int passingScorePercent;
  final List<_QuestionResult> results;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(passed ? 'Passed! 🎉' : 'Not quite there'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '$percent% ($earnedPoints / $totalGradablePoints points) '
              '· passing score: $passingScorePercent%',
            ),
            if (pendingPoints > 0) ...[
              const SizedBox(height: 8),
              Text(
                '$pendingPoints point(s) pending manual grading (essay).',
                style: const TextStyle(color: Colors.grey),
              ),
            ],
            const Divider(height: 24),
            for (int i = 0; i < results.length; i++)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
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
                          : (results[i].correct == true
                                ? Colors.green
                                : Colors.red),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Q${i + 1}: ${results[i].question.text}',
                        style: const TextStyle(fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
      actions: [
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.black,
            foregroundColor: Colors.white,
          ),
          onPressed: onClose,
          child: const Text('Done'),
        ),
      ],
    );
  }
}
