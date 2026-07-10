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
          appBar: AppBar(
            title: Text(quiz.title, overflow: TextOverflow.ellipsis),
            backgroundColor: Colors.black,
            foregroundColor: Colors.white,
            elevation: 0,
            actions: [
              IconButton(
                icon: const Icon(Icons.settings_outlined),
                tooltip: 'Quiz settings',
                onPressed: () => _openSettings(context, controller, quiz),
              ),
            ],
          ),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () => _addQuestion(context, controller, quiz),
            backgroundColor: Colors.black,
            foregroundColor: Colors.white,
            icon: const Icon(Icons.add),
            label: const Text('Add Question'),
          ),
          body: Column(
            children: [
              _QuizSummaryHeader(quiz: quiz),
              const Divider(height: 1),
              Expanded(
                child: quiz.questions.isEmpty
                    ? const _NoQuestionsState()
                    : ReorderableListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 96),
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
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Choose question type',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 12),
                ...QuestionType.values.map(
                  (type) => ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: CircleAvatar(
                      backgroundColor: Colors.black,
                      child: Icon(
                        _iconFor(type),
                        color: Colors.white,
                        size: 18,
                      ),
                    ),
                    title: Text(
                      type.label,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    subtitle: Text(type.description),
                    onTap: () => Navigator.pop(context, type),
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
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.of(context).viewInsets.bottom + 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Quiz settings',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: titleController,
                decoration: const InputDecoration(labelText: 'Title'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: descController,
                maxLines: 2,
                decoration: const InputDecoration(labelText: 'Description'),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: timeController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Time limit (min, optional)',
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: passController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Passing score %',
                      ),
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
                  child: const Text('Save Settings'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _QuizSummaryHeader extends StatelessWidget {
  const _QuizSummaryHeader({required this.quiz});

  final Quiz quiz;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: Colors.black,
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (quiz.description.isNotEmpty)
            Text(
              quiz.description,
              style: const TextStyle(color: Color(0xFFE0E0E0), fontSize: 13),
            ),
          const SizedBox(height: 12),
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
}

class _StatChip extends StatelessWidget {
  const _StatChip({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF2E2E2E)),
      ),
      child: Text(
        label,
        style: const TextStyle(color: Colors.white, fontSize: 12),
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
            const Icon(Icons.playlist_add, size: 56, color: Colors.grey),
            const SizedBox(height: 16),
            const Text(
              'No questions yet',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            const Text(
              'Tap "Add Question" and choose a type to get started.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
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
    return Card(
      elevation: 0,
      margin: const EdgeInsets.symmetric(vertical: 6),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: const BorderSide(color: Color(0xFFD6D6D6)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              radius: 14,
              backgroundColor: const Color(0xFFF5F5F5),
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
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    question.text,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _summary,
                    style: const TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                ],
              ),
            ),
            Column(
              children: [
                IconButton(
                  icon: const Icon(Icons.edit_outlined, size: 20),
                  onPressed: onEdit,
                  color: Colors.black,
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline, size: 20),
                  onPressed: onDelete,
                  color: Colors.grey,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
