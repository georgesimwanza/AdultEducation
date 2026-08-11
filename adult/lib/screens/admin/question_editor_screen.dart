import 'package:adult/Controller/quiz_admin_controller.dart';
import 'package:adult/Model/question.dart';
import 'package:adult/Model/quiz.dart';
import 'package:flutter/material.dart';

/// Hosts a single question's editor form. Which form actually renders
/// depends entirely on [type] / [initial]'s runtime type — the exhaustive
/// switch in [build] is the one place that maps question type to widget.
/// Adding a 5th question type later means adding one case here (and a
/// new Question subclass + form) — the Dart analyzer forces every switch
/// on the sealed Question type to be updated, so nothing gets missed.
class QuestionEditorScreen extends StatelessWidget {
  const QuestionEditorScreen({
    super.key,
    required this.quiz,
    required this.type,
    required this.controller,
    this.initial,
  });

  final Quiz quiz;
  final QuestionType type;
  final QuizAdminController controller;
  final Question? initial;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _Header(
              title: initial == null
                  ? 'Add ${type.label} Question'
                  : 'Edit Question',
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: switch (type) {
                  QuestionType.multipleChoice => _MultipleChoiceForm(
                    initial: initial as MultipleChoiceQuestion?,
                    onSave: (q) async {
                      await controller.upsertQuestion(quiz, q);
                      if (context.mounted) Navigator.pop(context);
                    },
                  ),
                  QuestionType.trueFalse => _TrueFalseForm(
                    initial: initial as TrueFalseQuestion?,
                    onSave: (q) async {
                      await controller.upsertQuestion(quiz, q);
                      if (context.mounted) Navigator.pop(context);
                    },
                  ),
                  QuestionType.shortAnswer => _ShortAnswerForm(
                    initial: initial as ShortAnswerQuestion?,
                    onSave: (q) async {
                      await controller.upsertQuestion(quiz, q);
                      if (context.mounted) Navigator.pop(context);
                    },
                  ),
                  QuestionType.essay => _EssayForm(
                    initial: initial as EssayQuestion?,
                    onSave: (q) async {
                      await controller.upsertQuestion(quiz, q);
                      if (context.mounted) Navigator.pop(context);
                    },
                  ),
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.title});
  final String title;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(28),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: const Color(0xFF262626),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.arrow_back_ios_new_rounded,
                size: 16,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              title,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Shared field decoration used by every form below — soft grey fill,
/// no visible border, matching the rest of the app.
InputDecoration _fieldDecoration(String label, {String? hint}) {
  return InputDecoration(
    labelText: label,
    hintText: hint,
    filled: true,
    fillColor: const Color(0xFFF5F5F5),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide.none,
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: Colors.redAccent),
    ),
    focusedErrorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: Colors.redAccent, width: 1.6),
    ),
    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
  );
}

Widget _sectionLabel(String text) {
  return Text(
    text,
    style: const TextStyle(
      fontSize: 13,
      fontWeight: FontWeight.w700,
      color: Colors.black,
    ),
  );
}

Widget _saveButton(VoidCallback onPressed) {
  return SizedBox(
    width: double.infinity,
    child: ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 15),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
        elevation: 0,
      ),
      onPressed: onPressed,
      child: const Text(
        'Save Question',
        style: TextStyle(fontWeight: FontWeight.w700),
      ),
    ),
  );
}

// ── Multiple Choice ──────────────────────────────────────────────────

class _MultipleChoiceForm extends StatefulWidget {
  const _MultipleChoiceForm({this.initial, required this.onSave});
  final MultipleChoiceQuestion? initial;
  final void Function(MultipleChoiceQuestion) onSave;

  @override
  State<_MultipleChoiceForm> createState() => _MultipleChoiceFormState();
}

class _MultipleChoiceFormState extends State<_MultipleChoiceForm> {
  final _formKey = GlobalKey<FormState>();
  late final _questionController = TextEditingController(
    text: widget.initial?.text ?? '',
  );
  late final _pointsController = TextEditingController(
    text: (widget.initial?.points ?? 1).toString(),
  );
  late final _explanationController = TextEditingController(
    text: widget.initial?.explanation ?? '',
  );
  late List<TextEditingController> _optionControllers =
      (widget.initial?.options ?? ['', ''])
          .map((o) => TextEditingController(text: o))
          .toList();
  late int _correctIndex = widget.initial?.correctOptionIndex ?? 0;

  void _addOption() =>
      setState(() => _optionControllers.add(TextEditingController()));

  void _removeOption(int index) {
    if (_optionControllers.length <= 2) return;
    setState(() {
      _optionControllers.removeAt(index).dispose();
      if (_correctIndex >= _optionControllers.length) {
        _correctIndex = _optionControllers.length - 1;
      }
    });
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    widget.onSave(
      MultipleChoiceQuestion(
        id:
            widget.initial?.id ??
            'mcq_${DateTime.now().microsecondsSinceEpoch}',
        text: _questionController.text.trim(),
        points: int.tryParse(_pointsController.text) ?? 1,
        explanation: _explanationController.text.trim().isEmpty
            ? null
            : _explanationController.text.trim(),
        options: _optionControllers.map((c) => c.text.trim()).toList(),
        correctOptionIndex: _correctIndex,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextFormField(
            controller: _questionController,
            maxLines: 3,
            decoration: _fieldDecoration('Question text'),
            validator: (v) => (v == null || v.trim().isEmpty)
                ? 'Question text is required'
                : null,
          ),
          const SizedBox(height: 14),
          TextFormField(
            controller: _pointsController,
            keyboardType: TextInputType.number,
            decoration: _fieldDecoration('Points'),
            validator: (v) => (int.tryParse(v ?? '') ?? 0) > 0
                ? null
                : 'Enter a valid point value',
          ),
          const SizedBox(height: 22),
          _sectionLabel('Options'),
          const SizedBox(height: 10),
          ..._optionControllers.asMap().entries.map((entry) {
            final index = entry.key;
            final controller = entry.value;
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                children: [
                  Radio<int>(
                    value: index,
                    groupValue: _correctIndex,
                    activeColor: Colors.black,
                    onChanged: (v) => setState(() => _correctIndex = v!),
                  ),
                  Expanded(
                    child: TextFormField(
                      controller: controller,
                      decoration: _fieldDecoration('Option ${index + 1}'),
                      validator: (v) => (v == null || v.trim().isEmpty)
                          ? 'Option cannot be empty'
                          : null,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.remove_circle_outline),
                    color: Colors.black38,
                    onPressed: _optionControllers.length > 2
                        ? () => _removeOption(index)
                        : null,
                  ),
                ],
              ),
            );
          }),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: _addOption,
              style: TextButton.styleFrom(foregroundColor: Colors.black),
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Add option'),
            ),
          ),
          Text(
            'Select the radio button next to the correct option.',
            style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _explanationController,
            maxLines: 2,
            decoration: _fieldDecoration('Explanation (optional)'),
          ),
          const SizedBox(height: 24),
          _saveButton(_submit),
        ],
      ),
    );
  }
}

// ── True / False ─────────────────────────────────────────────────────

class _TrueFalseForm extends StatefulWidget {
  const _TrueFalseForm({this.initial, required this.onSave});
  final TrueFalseQuestion? initial;
  final void Function(TrueFalseQuestion) onSave;

  @override
  State<_TrueFalseForm> createState() => _TrueFalseFormState();
}

class _TrueFalseFormState extends State<_TrueFalseForm> {
  final _formKey = GlobalKey<FormState>();
  late final _questionController = TextEditingController(
    text: widget.initial?.text ?? '',
  );
  late final _pointsController = TextEditingController(
    text: (widget.initial?.points ?? 1).toString(),
  );
  late final _explanationController = TextEditingController(
    text: widget.initial?.explanation ?? '',
  );
  late bool _correctAnswer = widget.initial?.correctAnswer ?? true;

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    widget.onSave(
      TrueFalseQuestion(
        id: widget.initial?.id ?? 'tf_${DateTime.now().microsecondsSinceEpoch}',
        text: _questionController.text.trim(),
        points: int.tryParse(_pointsController.text) ?? 1,
        explanation: _explanationController.text.trim().isEmpty
            ? null
            : _explanationController.text.trim(),
        correctAnswer: _correctAnswer,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextFormField(
            controller: _questionController,
            maxLines: 3,
            decoration: _fieldDecoration('Statement'),
            validator: (v) => (v == null || v.trim().isEmpty)
                ? 'Statement is required'
                : null,
          ),
          const SizedBox(height: 14),
          TextFormField(
            controller: _pointsController,
            keyboardType: TextInputType.number,
            decoration: _fieldDecoration('Points'),
            validator: (v) => (int.tryParse(v ?? '') ?? 0) > 0
                ? null
                : 'Enter a valid point value',
          ),
          const SizedBox(height: 22),
          _sectionLabel('Correct answer'),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _ToggleTile(
                  label: 'True',
                  selected: _correctAnswer,
                  onTap: () => setState(() => _correctAnswer = true),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _ToggleTile(
                  label: 'False',
                  selected: !_correctAnswer,
                  onTap: () => setState(() => _correctAnswer = false),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _explanationController,
            maxLines: 2,
            decoration: _fieldDecoration('Explanation (optional)'),
          ),
          const SizedBox(height: 24),
          _saveButton(_submit),
        ],
      ),
    );
  }
}

class _ToggleTile extends StatelessWidget {
  const _ToggleTile({
    required this.label,
    required this.selected,
    required this.onTap,
  });
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? Colors.black : const Color(0xFFF5F5F5),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.white : Colors.black,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

// ── Short Answer ─────────────────────────────────────────────────────

class _ShortAnswerForm extends StatefulWidget {
  const _ShortAnswerForm({this.initial, required this.onSave});
  final ShortAnswerQuestion? initial;
  final void Function(ShortAnswerQuestion) onSave;

  @override
  State<_ShortAnswerForm> createState() => _ShortAnswerFormState();
}

class _ShortAnswerFormState extends State<_ShortAnswerForm> {
  final _formKey = GlobalKey<FormState>();
  late final _questionController = TextEditingController(
    text: widget.initial?.text ?? '',
  );
  late final _pointsController = TextEditingController(
    text: (widget.initial?.points ?? 1).toString(),
  );
  late final _explanationController = TextEditingController(
    text: widget.initial?.explanation ?? '',
  );
  late List<TextEditingController> _answerControllers =
      (widget.initial?.acceptedAnswers ?? [''])
          .map((a) => TextEditingController(text: a))
          .toList();
  late bool _caseSensitive = widget.initial?.caseSensitive ?? false;

  void _addAnswer() =>
      setState(() => _answerControllers.add(TextEditingController()));

  void _removeAnswer(int index) {
    if (_answerControllers.length <= 1) return;
    setState(() => _answerControllers.removeAt(index).dispose());
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    widget.onSave(
      ShortAnswerQuestion(
        id: widget.initial?.id ?? 'sa_${DateTime.now().microsecondsSinceEpoch}',
        text: _questionController.text.trim(),
        points: int.tryParse(_pointsController.text) ?? 1,
        explanation: _explanationController.text.trim().isEmpty
            ? null
            : _explanationController.text.trim(),
        acceptedAnswers: _answerControllers
            .map((c) => c.text.trim())
            .where((a) => a.isNotEmpty)
            .toList(),
        caseSensitive: _caseSensitive,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextFormField(
            controller: _questionController,
            maxLines: 3,
            decoration: _fieldDecoration('Question text'),
            validator: (v) => (v == null || v.trim().isEmpty)
                ? 'Question text is required'
                : null,
          ),
          const SizedBox(height: 14),
          TextFormField(
            controller: _pointsController,
            keyboardType: TextInputType.number,
            decoration: _fieldDecoration('Points'),
            validator: (v) => (int.tryParse(v ?? '') ?? 0) > 0
                ? null
                : 'Enter a valid point value',
          ),
          const SizedBox(height: 22),
          _sectionLabel('Accepted answers'),
          const SizedBox(height: 4),
          Text(
            'Add every wording that should be marked correct.',
            style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
          ),
          const SizedBox(height: 10),
          ..._answerControllers.asMap().entries.map((entry) {
            final index = entry.key;
            final controller = entry.value;
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: controller,
                      decoration: _fieldDecoration('Answer ${index + 1}'),
                      validator: (v) => (v == null || v.trim().isEmpty)
                          ? 'Answer cannot be empty'
                          : null,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.remove_circle_outline),
                    color: Colors.black38,
                    onPressed: _answerControllers.length > 1
                        ? () => _removeAnswer(index)
                        : null,
                  ),
                ],
              ),
            );
          }),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: _addAnswer,
              style: TextButton.styleFrom(foregroundColor: Colors.black),
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Add accepted answer'),
            ),
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            activeColor: Colors.black,
            title: const Text('Case sensitive'),
            value: _caseSensitive,
            onChanged: (v) => setState(() => _caseSensitive = v),
          ),
          const SizedBox(height: 4),
          TextFormField(
            controller: _explanationController,
            maxLines: 2,
            decoration: _fieldDecoration('Explanation (optional)'),
          ),
          const SizedBox(height: 24),
          _saveButton(_submit),
        ],
      ),
    );
  }
}

// ── Essay ─────────────────────────────────────────────────────────────

class _EssayForm extends StatefulWidget {
  const _EssayForm({this.initial, required this.onSave});
  final EssayQuestion? initial;
  final void Function(EssayQuestion) onSave;

  @override
  State<_EssayForm> createState() => _EssayFormState();
}

class _EssayFormState extends State<_EssayForm> {
  final _formKey = GlobalKey<FormState>();
  late final _questionController = TextEditingController(
    text: widget.initial?.text ?? '',
  );
  late final _pointsController = TextEditingController(
    text: (widget.initial?.points ?? 5).toString(),
  );
  late final _explanationController = TextEditingController(
    text: widget.initial?.explanation ?? '',
  );
  late final _minWordsController = TextEditingController(
    text: widget.initial?.minWords?.toString() ?? '',
  );
  late final _maxWordsController = TextEditingController(
    text: widget.initial?.maxWords?.toString() ?? '',
  );
  late final _rubricController = TextEditingController(
    text: widget.initial?.rubric ?? '',
  );

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    widget.onSave(
      EssayQuestion(
        id: widget.initial?.id ?? 'es_${DateTime.now().microsecondsSinceEpoch}',
        text: _questionController.text.trim(),
        points: int.tryParse(_pointsController.text) ?? 5,
        explanation: _explanationController.text.trim().isEmpty
            ? null
            : _explanationController.text.trim(),
        minWords: int.tryParse(_minWordsController.text),
        maxWords: int.tryParse(_maxWordsController.text),
        rubric: _rubricController.text.trim().isEmpty
            ? null
            : _rubricController.text.trim(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextFormField(
            controller: _questionController,
            maxLines: 3,
            decoration: _fieldDecoration('Essay prompt'),
            validator: (v) =>
                (v == null || v.trim().isEmpty) ? 'Prompt is required' : null,
          ),
          const SizedBox(height: 14),
          TextFormField(
            controller: _pointsController,
            keyboardType: TextInputType.number,
            decoration: _fieldDecoration('Points'),
            validator: (v) => (int.tryParse(v ?? '') ?? 0) > 0
                ? null
                : 'Enter a valid point value',
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _minWordsController,
                  keyboardType: TextInputType.number,
                  decoration: _fieldDecoration('Min words (optional)'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextFormField(
                  controller: _maxWordsController,
                  keyboardType: TextInputType.number,
                  decoration: _fieldDecoration('Max words (optional)'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          TextFormField(
            controller: _rubricController,
            maxLines: 3,
            decoration: _fieldDecoration(
              'Grading rubric (optional)',
              hint: 'Guidance shown to instructors when manually grading',
            ),
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF5F5F5),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, size: 18, color: Colors.grey.shade600),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Essay answers are always graded manually by an instructor.',
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _explanationController,
            maxLines: 2,
            decoration: _fieldDecoration('Explanation (optional)'),
          ),
          const SizedBox(height: 24),
          _saveButton(_submit),
        ],
      ),
    );
  }
}
