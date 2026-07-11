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
      appBar: AppBar(
        title: Text(
          initial == null ? 'Add ${type.label} Question' : 'Edit Question',
        ),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: switch (type) {
          QuestionType.multipleChoice => _MultipleChoiceForm(
            initial: initial as MultipleChoiceQuestion?,
            onSave: (q) {
              controller.upsertQuestion(quiz, q);
              Navigator.pop(context);
            },
          ),
          QuestionType.trueFalse => _TrueFalseForm(
            initial: initial as TrueFalseQuestion?,
            onSave: (q) {
              controller.upsertQuestion(quiz, q);
              Navigator.pop(context);
            },
          ),
          QuestionType.shortAnswer => _ShortAnswerForm(
            initial: initial as ShortAnswerQuestion?,
            onSave: (q) {
              controller.upsertQuestion(quiz, q);
              Navigator.pop(context);
            },
          ),
          QuestionType.essay => _EssayForm(
            initial: initial as EssayQuestion?,
            onSave: (q) {
              controller.upsertQuestion(quiz, q);
              Navigator.pop(context);
            },
          ),
        },
      ),
    );
  }
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
            decoration: const InputDecoration(labelText: 'Question text'),
            validator: (v) => (v == null || v.trim().isEmpty)
                ? 'Question text is required'
                : null,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _pointsController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: 'Points'),
            validator: (v) => (int.tryParse(v ?? '') ?? 0) > 0
                ? null
                : 'Enter a valid point value',
          ),
          const SizedBox(height: 20),
          Text('Options', style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 8),
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
                      decoration: InputDecoration(
                        labelText: 'Option ${index + 1}',
                      ),
                      validator: (v) => (v == null || v.trim().isEmpty)
                          ? 'Option cannot be empty'
                          : null,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.remove_circle_outline),
                    color: Colors.grey,
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
              icon: const Icon(Icons.add),
              label: const Text('Add option'),
            ),
          ),
          const Text(
            'Select the radio button next to the correct option.',
            style: TextStyle(color: Colors.grey, fontSize: 12),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _explanationController,
            maxLines: 2,
            decoration: const InputDecoration(
              labelText: 'Explanation (optional)',
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black,
                foregroundColor: Colors.white,
              ),
              onPressed: _submit,
              child: const Text('Save Question'),
            ),
          ),
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
            decoration: const InputDecoration(labelText: 'Statement'),
            validator: (v) => (v == null || v.trim().isEmpty)
                ? 'Statement is required'
                : null,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _pointsController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: 'Points'),
            validator: (v) => (int.tryParse(v ?? '') ?? 0) > 0
                ? null
                : 'Enter a valid point value',
          ),
          const SizedBox(height: 20),
          Text('Correct answer', style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 8),
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
            decoration: const InputDecoration(
              labelText: 'Explanation (optional)',
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black,
                foregroundColor: Colors.white,
              ),
              onPressed: _submit,
              child: const Text('Save Question'),
            ),
          ),
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
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? Colors.black : const Color(0xFFF5F5F5),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: selected ? Colors.black : const Color(0xFFD6D6D6),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.white : Colors.black,
            fontWeight: FontWeight.w600,
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
            decoration: const InputDecoration(labelText: 'Question text'),
            validator: (v) => (v == null || v.trim().isEmpty)
                ? 'Question text is required'
                : null,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _pointsController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: 'Points'),
            validator: (v) => (int.tryParse(v ?? '') ?? 0) > 0
                ? null
                : 'Enter a valid point value',
          ),
          const SizedBox(height: 20),
          Text(
            'Accepted answers',
            style: Theme.of(context).textTheme.titleSmall,
          ),
          const Text(
            'Add every wording that should be marked correct.',
            style: TextStyle(color: Colors.grey, fontSize: 12),
          ),
          const SizedBox(height: 8),
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
                      decoration: InputDecoration(
                        labelText: 'Answer ${index + 1}',
                      ),
                      validator: (v) => (v == null || v.trim().isEmpty)
                          ? 'Answer cannot be empty'
                          : null,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.remove_circle_outline),
                    color: Colors.grey,
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
              icon: const Icon(Icons.add),
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
          TextFormField(
            controller: _explanationController,
            maxLines: 2,
            decoration: const InputDecoration(
              labelText: 'Explanation (optional)',
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black,
                foregroundColor: Colors.white,
              ),
              onPressed: _submit,
              child: const Text('Save Question'),
            ),
          ),
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
            decoration: const InputDecoration(labelText: 'Essay prompt'),
            validator: (v) =>
                (v == null || v.trim().isEmpty) ? 'Prompt is required' : null,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _pointsController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: 'Points'),
            validator: (v) => (int.tryParse(v ?? '') ?? 0) > 0
                ? null
                : 'Enter a valid point value',
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _minWordsController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Min words (optional)',
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextFormField(
                  controller: _maxWordsController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Max words (optional)',
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _rubricController,
            maxLines: 3,
            decoration: const InputDecoration(
              labelText: 'Grading rubric (optional)',
              hintText: 'Guidance shown to instructors when manually grading',
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF5F5F5),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Row(
              children: [
                Icon(Icons.info_outline, size: 18, color: Colors.grey),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Essay answers are always graded manually by an instructor.',
                    style: TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _explanationController,
            maxLines: 2,
            decoration: const InputDecoration(
              labelText: 'Explanation (optional)',
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black,
                foregroundColor: Colors.white,
              ),
              onPressed: _submit,
              child: const Text('Save Question'),
            ),
          ),
        ],
      ),
    );
  }
}
