import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../Controller/quiz_admin_controller.dart';
import '../../Model/quiz.dart';
import 'quiz_editor_screen.dart';

/// Drop-in replacement for the placeholder QuizScreen tab in AdminNavBar.
///
/// Self-contained: creates its own QuizAdminController, so you don't need
/// to touch main.dart or AdminNavBar. Because AdminNavBar keeps this
/// widget alive inside an IndexedStack, the loaded quiz list persists as
/// the teacher switches between the other tabs (no need to refetch).
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

class _QuizListView extends StatefulWidget {
  const _QuizListView();

  @override
  State<_QuizListView> createState() => _QuizListViewState();
}

class _QuizListViewState extends State<_QuizListView> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<QuizAdminController>().loadQuizzes();
    });
  }

  Future<void> _createQuiz() async {
    final titleController = TextEditingController();
    final subjectIdController = TextEditingController();
    final institutionIdController = TextEditingController();
    final programmeIdController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('New quiz'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: titleController,
                autofocus: true,
                decoration: const InputDecoration(labelText: 'Quiz title'),
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? 'Title is required'
                    : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: subjectIdController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Subject ID'),
                validator: (v) => int.tryParse(v ?? '') == null
                    ? 'Enter a valid subject ID'
                    : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: institutionIdController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Institution ID'),
                validator: (v) => int.tryParse(v ?? '') == null
                    ? 'Enter a valid institution ID'
                    : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: programmeIdController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Programme ID'),
                validator: (v) => int.tryParse(v ?? '') == null
                    ? 'Enter a valid programme ID'
                    : null,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                Navigator.pop(context, true);
              }
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    final controller = context.read<QuizAdminController>();
    try {
      final quiz = await controller.createQuiz(
        titleController.text.trim(),
        subjectId: int.parse(subjectIdController.text),
        institutionId: int.parse(institutionIdController.text),
        programmeId: int.parse(programmeIdController.text),
      );
      if (!mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ChangeNotifierProvider.value(
            value: controller,
            child: QuizEditorScreen(quizId: quiz.id),
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Could not create quiz: $e')));
    }
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
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => context.read<QuizAdminController>().loadQuizzes(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _createQuiz,
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('New Quiz'),
      ),
      body: Consumer<QuizAdminController>(
        builder: (context, controller, _) {
          if (controller.isLoading && controller.quizzes.isEmpty) {
            return const Center(
              child: CircularProgressIndicator(color: Colors.black),
            );
          }
          if (controller.errorMessage != null && controller.quizzes.isEmpty) {
            return _ErrorState(
              message: controller.errorMessage!,
              onRetry: () => controller.loadQuizzes(),
            );
          }
          if (controller.quizzes.isEmpty) {
            return const _EmptyState();
          }
          return RefreshIndicator(
            onRefresh: controller.loadQuizzes,
            child: ListView.separated(
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
                  onDelete: () async {
                    try {
                      await controller.deleteQuiz(quiz.id);
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Could not delete quiz: $e')),
                        );
                      }
                    }
                  },
                );
              },
            ),
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

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off, size: 56, color: Colors.grey),
            const SizedBox(height: 16),
            const Text(
              'Could not reach the server',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black,
                foregroundColor: Colors.white,
              ),
              onPressed: onRetry,
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}
