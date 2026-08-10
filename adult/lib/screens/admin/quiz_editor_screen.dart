import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../Controller/quiz_admin_controller.dart';
import '../../Model/question.dart';
import '../../Model/quiz.dart';
import 'question_editor_screen.dart';

/// Shows one quiz's metadata plus its ordered, mixed-type question list.
/// Teachers can reorder questions by dragging, edit quiz settings, and
/// add a question of any of the four supported types.
class QuizEditorScreen extends StatelessWidget {
  const QuizEditorScreen({super.key, required this.quizId});

  final String quizId;

  @override
  Widget build(BuildContext context) {
    return Consumer<QuizAdminController>(
      builder: (context, controller, _) {
        final quiz = controller.quizzes.firstWhere((q) => q.id == quizId);
        return Scaffold(
          backgroundColor: Colors.white,
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () => _addQuestion(context, controller, quiz),
            backgroundColor: Colors.black,
            foregroundColor: Colors.white,
            icon: const Icon(Icons.add),
            label: const Text('Add Question'),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(30),
            ),
          ),
          body: SafeArea(
            child: Column(
              children: [
                _QuizSummaryHeader(
                  quiz: quiz,
                  onSettings: () => _openSettings(context, controller, quiz),
                ),
                Expanded(
                  child: quiz.questions.isEmpty
                      ? const _NoQuestionsState()
                      : ReorderableListView.builder(
                          padding: const EdgeInsets.fromLTRB(20, 16, 20, 96),
                          itemCount: quiz.questions.length,
                          onReorder: (oldIndex, newIndex) => controller
                              .reorderQuestions(quiz, oldIndex, newIndex),
                          itemBuilder: (context, index) {
                            final question = quiz.questions[index];
                            return _QuestionCard(
                              key: ValueKey(question.id),
                              question: question,
                              index: index,
                              onEdit: () => _editQuestion(
                                context,
                                controller,
                                quiz,
                                question,
                              ),
                              onDelete: () =>
                                  controller.removeQuestion(quiz, question.id),
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _addQuestion(
    BuildContext context,
    QuizAdminController controller,
    Quiz quiz,
  ) async {
    final type = await _pickQuestionType(context);
    if (type == null || !context.mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => QuestionEditorScreen(
          quiz: quiz,
          type: type,
          controller: controller,
        ),
      ),
    );
  }

  void _editQuestion(
    BuildContext context,
    QuizAdminController controller,
    Quiz quiz,
    Question question,
  ) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => QuestionEditorScreen(
          quiz: quiz,
          type: question.type,
          initial: question,
          controller: controller,
        ),
      ),
    );
  }

  Future<QuestionType?> _pickQuestionType(BuildContext context) {
    return showModalBottomSheet<QuestionType>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Choose question type',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 12),
                ...QuestionType.values.map(
                  (type) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(14),
                      onTap: () => Navigator.pop(context, type),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF7F7F7),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 38,
                              height: 38,
                              decoration: BoxDecoration(
                                color: Colors.black,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                _iconFor(type),
                                color: Colors.white,
                                size: 18,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    type.label,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 14,
                                      color: Colors.black,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    type.description,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  IconData _iconFor(QuestionType type) => switch (type) {
    QuestionType.multipleChoice => Icons.checklist_rtl,
    QuestionType.trueFalse => Icons.rule,
    QuestionType.shortAnswer => Icons.short_text,
    QuestionType.essay => Icons.notes,
  };

  void _openSettings(
    BuildContext context,
    QuizAdminController controller,
    Quiz quiz,
  ) {
    final titleController = TextEditingController(text: quiz.title);
    final descController = TextEditingController(text: quiz.description);
    final timeController = TextEditingController(
      text: quiz.timeLimitMinutes?.toString() ?? '',
    );
    final passController = TextEditingController(
      text: quiz.passingScorePercent.toString(),
    );

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            left: 24,
            right: 24,
            top: 24,
            bottom: MediaQuery.of(context).viewInsets.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Quiz settings',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 16),
              _settingsField(controller: titleController, label: 'Title'),
              const SizedBox(height: 12),
              _settingsField(
                controller: descController,
                label: 'Description',
                maxLines: 2,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _settingsField(
                      controller: timeController,
                      label: 'Time limit (min, optional)',
                      numeric: true,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _settingsField(
                      controller: passController,
                      label: 'Passing score %',
                      numeric: true,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                    elevation: 0,
                  ),
                  onPressed: () {
                    controller.updateQuiz(
                      quiz.copyWith(
                        title: titleController.text.trim().isEmpty
                            ? quiz.title
                            : titleController.text.trim(),
                        description: descController.text.trim(),
                        timeLimitMinutes: int.tryParse(timeController.text),
                        passingScorePercent:
                            int.tryParse(passController.text) ??
                            quiz.passingScorePercent,
                      ),
                    );
                    Navigator.pop(context);
                  },
                  child: const Text(
                    'Save Settings',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _settingsField({
    required TextEditingController controller,
    required String label,
    int maxLines = 1,
    bool numeric = false,
  }) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: numeric ? TextInputType.number : TextInputType.text,
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor: const Color(0xFFF5F5F5),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 14,
        ),
      ),
    );
  }
}

class _QuizSummaryHeader extends StatelessWidget {
  const _QuizSummaryHeader({required this.quiz, required this.onSettings});

  final Quiz quiz;
  final VoidCallback onSettings;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 22),
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(28),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _circleIconButton(
                Icons.arrow_back_ios_new_rounded,
                onTap: () => Navigator.pop(context),
              ),
              _circleIconButton(Icons.settings_outlined, onTap: onSettings),
            ],
          ),
          const SizedBox(height: 18),
          Text(
            quiz.title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w800,
              height: 1.15,
            ),
          ),
          if (quiz.description.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              quiz.description,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: Color(0xFFB3B3B3), fontSize: 13),
            ),
          ],
          const SizedBox(height: 16),
          Row(
            children: [
              _StatChip(label: '${quiz.questionCount} questions'),
              const SizedBox(width: 8),
              _StatChip(label: '${quiz.totalPoints} points'),
              const SizedBox(width: 8),
              _StatChip(
                label: quiz.timeLimitMinutes != null
                    ? '${quiz.timeLimitMinutes} min'
                    : 'No time limit',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _circleIconButton(IconData icon, {required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: const Color(0xFF262626),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, size: 16, color: Colors.white),
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  const _StatChip({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF2E2E2E)),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _NoQuestionsState extends StatelessWidget {
  const _NoQuestionsState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.playlist_add, size: 56, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            const Text(
              'No questions yet',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Tap "Add Question" and choose a type to get started.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade500),
            ),
          ],
        ),
      ),
    );
  }
}

/// One question row in the list, with a type badge and a type-specific
/// one-line summary.
class _QuestionCard extends StatelessWidget {
  const _QuestionCard({
    super.key,
    required this.question,
    required this.index,
    required this.onEdit,
    required this.onDelete,
  });

  final Question question;
  final int index;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  String get _summary => switch (question) {
    MultipleChoiceQuestion q => '${q.options.length} options',
    TrueFalseQuestion q => 'Answer: ${q.correctAnswer ? 'True' : 'False'}',
    ShortAnswerQuestion q => '${q.acceptedAnswers.length} accepted answer(s)',
    EssayQuestion _ => 'Manually graded',
  };

  IconData get _icon => switch (question.type) {
    QuestionType.multipleChoice => Icons.checklist_rtl,
    QuestionType.trueFalse => Icons.rule,
    QuestionType.shortAnswer => Icons.short_text,
    QuestionType.essay => Icons.notes,
  };

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFEDEDED)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: const Color(0xFFF0F0F0),
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: Text(
                '${index + 1}',
                style: const TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(_icon, size: 13, color: Colors.white),
                            const SizedBox(width: 5),
                            Text(
                              question.type.label,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Spacer(),
                      Text(
                        '${question.points} pt${question.points == 1 ? '' : 's'}',
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    question.text,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _summary,
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                  ),
                ],
              ),
            ),
            Column(
              children: [
                IconButton(
                  icon: const Icon(Icons.edit_outlined, size: 19),
                  onPressed: onEdit,
                  color: Colors.black,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(
                    minWidth: 32,
                    minHeight: 32,
                  ),
                ),
                const SizedBox(height: 4),
                IconButton(
                  icon: const Icon(Icons.delete_outline, size: 19),
                  onPressed: onDelete,
                  color: Colors.black38,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(
                    minWidth: 32,
                    minHeight: 32,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
