import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../Controller/quiz_admin_controller.dart';
import '../../Model/quiz.dart';
import 'quiz_editor_screen.dart';

/// Drop-in replacement for the placeholder QuizScreen tab in AdminNavBar.
///
/// Self-contained: creates its own QuizAdminController, so you don't need
/// to touch main.dart or AdminNavBar. Because AdminNavBar keeps this
/// widget alive inside an IndexedStack, quizzes the teacher adds persist
/// as they switch between the other tabs.
class QuizScreen extends StatelessWidget {
  const QuizScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => QuizAdminController(),
      child: const _QuizListView(),
    );
  }
}

class _QuizListView extends StatelessWidget {
  const _QuizListView();

  Future<void> _createQuiz(BuildContext context) async {
    final titleController = TextEditingController();
    final title = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('New quiz'),
        content: TextField(
          controller: titleController,
          autofocus: true,
          decoration: const InputDecoration(labelText: 'Quiz title'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () =>
                Navigator.pop(context, titleController.text.trim()),
            child: const Text('Create'),
          ),
        ],
      ),
    );

    if (title == null || title.isEmpty || !context.mounted) return;

    // Grab the controller instance *before* pushing. Navigator.push puts
    // the new screen in a separate branch of the widget tree (inside the
    // Overlay), so it can't look up a Provider that only wraps this tab.
    // We carry the same controller along explicitly instead.
    final controller = context.read<QuizAdminController>();
    final quiz = controller.createQuiz(title);
    if (!context.mounted) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ChangeNotifierProvider.value(
          value: controller,
          child: QuizEditorScreen(quizId: quiz.id),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Quiz Management'),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _createQuiz(context),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('New Quiz'),
      ),
      body: Consumer<QuizAdminController>(
        builder: (context, controller, _) {
          if (controller.quizzes.isEmpty) {
            return const _EmptyState();
          }
          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
            itemCount: controller.quizzes.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final quiz = controller.quizzes[index];
              return _QuizTile(
                quiz: quiz,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ChangeNotifierProvider.value(
                      value: controller,
                      child: QuizEditorScreen(quizId: quiz.id),
                    ),
                  ),
                ),
                onDelete: () => controller.deleteQuiz(quiz.id),
              );
            },
          );
        },
      ),
    );
  }
}

class _QuizTile extends StatelessWidget {
  const _QuizTile({
    required this.quiz,
    required this.onTap,
    required this.onDelete,
  });

  final Quiz quiz;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: Color(0xFFD6D6D6)),
      ),
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        title: Text(
          quiz.title,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          '${quiz.questionCount} question${quiz.questionCount == 1 ? '' : 's'} · ${quiz.totalPoints} points',
          style: const TextStyle(color: Colors.grey),
        ),
        trailing: IconButton(
          icon: const Icon(Icons.delete_outline, color: Colors.grey),
          onPressed: () => showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Delete quiz?'),
              content: Text(
                '"${quiz.title}" and all its questions will be removed.',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                    onDelete();
                  },
                  child: const Text(
                    'Delete',
                    style: TextStyle(color: Colors.red),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.quiz_outlined, size: 56, color: Colors.grey),
            const SizedBox(height: 16),
            const Text(
              'No quizzes yet',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            const Text(
              'Tap "New Quiz" to build your first assessment.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}
