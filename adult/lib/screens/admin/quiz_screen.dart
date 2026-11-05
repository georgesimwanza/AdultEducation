import 'package:adult/core/admin_table.dart';
import 'package:adult/core/responsive.dart';
import 'package:flutter/material.dart';
import 'package:adult/screens/color.dart';
import 'package:provider/provider.dart';
import '../../Controller/quiz_admin_controller.dart';
import '../../Model/quiz.dart';
import '../../Model/subject_model.dart';
import 'package:adult/service/auth_service.dart';
import 'package:adult/service/subject_service.dart';
import 'package:adult/service/sync_service.dart';
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
    final formKey = GlobalKey<FormState>();

    // Programmes and subjects come from the local copy synced at login, so
    // the admin picks names instead of typing IDs (works offline too).
    // The institution is the signed-in admin's own.
    final db = context.read<SyncService>().db;
    final institutionId = await AuthService().getInstitution();
    final programmes = db == null
        ? <Map<String, Object?>>[]
        : await db.query('programmes', orderBy: 'name');
    if (!mounted) return;
    if (institutionId == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('No institution found. Please log in again.'),
      ));
      return;
    }
    int? programmeId;
    int? subjectId;
    var subjects = <subjectModel>[];

    final confirmed = await showAdaptiveSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setSheetState) {
        return Padding(
          padding: EdgeInsets.only(
            left: 24,
            right: 24,
            top: 24,
            bottom: MediaQuery.of(context).viewInsets.bottom + 24,
          ),
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'New quiz',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: EduColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 16),
                _quizField(
                  controller: titleController,
                  label: 'Quiz title',
                  autofocus: true,
                  validator: (v) => (v == null || v.trim().isEmpty)
                      ? 'Title is required'
                      : null,
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<int>(
                  initialValue: programmeId,
                  isExpanded: true,
                  decoration: _pickerDecoration('Programme'),
                  hint: Text(programmes.isEmpty
                      ? 'No programmes available'
                      : 'Choose a programme'),
                  items: [
                    for (final p in programmes)
                      DropdownMenuItem(
                        value: p['id'] as int,
                        child: Text(
                          p['name'] as String? ?? '',
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                  ],
                  validator: (v) => v == null ? 'Choose a programme' : null,
                  onChanged: (v) async {
                    final list = v == null || db == null
                        ? <subjectModel>[]
                        : await subjectService(db: db)
                            .getSubjectsByProgramme(v);
                    setSheetState(() {
                      programmeId = v;
                      subjectId = null;
                      subjects = list;
                    });
                  },
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<int>(
                  // Rebuilt when the programme changes so the old pick clears.
                  key: ValueKey(programmeId),
                  initialValue: subjectId,
                  isExpanded: true,
                  decoration: _pickerDecoration('Subject'),
                  hint: Text(programmeId == null
                      ? 'Choose a programme first'
                      : subjects.isEmpty
                          ? 'No subjects in this programme'
                          : 'Choose a subject'),
                  items: [
                    for (final sub in subjects)
                      DropdownMenuItem(
                        value: sub.id,
                        child: Text(
                          sub.code.isEmpty ? sub.name : '${sub.name} (${sub.code})',
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                  ],
                  validator: (v) => v == null ? 'Choose a subject' : null,
                  onChanged: (v) => setSheetState(() => subjectId = v),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context, false),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 15),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                          side: const BorderSide(color: EduColors.textSecondary),
                        ),
                        child: const Text(
                          'Cancel',
                          style: TextStyle(
                            color: EduColors.textPrimary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          if (formKey.currentState!.validate()) {
                            Navigator.pop(context, true);
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: EduColors.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 15),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                          elevation: 0,
                        ),
                        child: const Text(
                          'Create',
                          style: TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
        },
      ),
    );

    if (confirmed != true || !mounted) return;

    final controller = context.read<QuizAdminController>();
    try {
      final quiz = await controller.createQuiz(
        titleController.text.trim(),
        subjectId: subjectId!,
        institutionId: institutionId,
        programmeId: programmeId!,
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

  InputDecoration _pickerDecoration(String label) {
    return InputDecoration(
      labelText: label,
      filled: true,
      fillColor: EduColors.background,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
    );
  }

  Widget _quizField({
    required TextEditingController controller,
    required String label,
    bool numeric = false,
    bool autofocus = false,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      autofocus: autofocus,
      keyboardType: numeric ? TextInputType.number : TextInputType.text,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor: EduColors.background,
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

  void _openQuiz(QuizAdminController controller, Quiz quiz) {
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

  Future<void> _deleteQuiz(QuizAdminController controller, Quiz quiz) async {
    try {
      await controller.deleteQuiz(quiz.id);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not delete quiz: $e')),
        );
      }
    }
  }

  /// Desktop: a sortable-looking table; tablet: a two-column grid.
  Widget _wideQuizList(QuizAdminController controller) {
    if (context.isDesktop) {
      return CenteredScrollPadding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
        builder: (context, padding) => AdminDataTable(
          padding: padding,
          columns: const [
            DataColumn(label: Text('Title')),
            DataColumn(label: Text('Questions'), numeric: true),
            DataColumn(label: Text('Points'), numeric: true),
            DataColumn(label: Text('')),
          ],
          rows: [
            for (final quiz in controller.quizzes)
              DataRow(
                onSelectChanged: (_) => _openQuiz(controller, quiz),
                cells: [
                  DataCell(Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.quiz_rounded, size: 18),
                      const SizedBox(width: 10),
                      TableText(
                        quiz.title,
                        maxWidth: 420,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ],
                  )),
                  DataCell(Text('${quiz.questionCount}')),
                  DataCell(Text('${quiz.totalPoints}')),
                  DataCell(Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        tooltip: 'Edit',
                        icon: const Icon(Icons.edit_outlined, size: 20),
                        onPressed: () => _openQuiz(controller, quiz),
                      ),
                      IconButton(
                        tooltip: 'Delete',
                        icon: const Icon(Icons.delete_outline,
                            color: EduColors.textSecondary, size: 20),
                        onPressed: () => _confirmDeleteQuiz(
                          context,
                          quiz,
                          () => _deleteQuiz(controller, quiz),
                        ),
                      ),
                    ],
                  )),
                ],
              ),
          ],
        ),
      );
    }
    return CenteredScrollPadding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
      builder: (context, padding) => SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: padding,
        child: ResponsiveGrid(
          spacing: 10,
          runSpacing: 10,
          children: [
            for (final quiz in controller.quizzes)
              _QuizTile(
                quiz: quiz,
                onTap: () => _openQuiz(controller, quiz),
                onDelete: () => _deleteQuiz(controller, quiz),
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: EduColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // ── Header ──────────────────────────────────────────
            ResponsiveCenter(child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Text(
                        'Quiz Management',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: EduColors.textPrimary,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Consumer<QuizAdminController>(
                        builder: (context, controller, _) {
                          return Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: EduColors.primarySoft,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              '${controller.quizzes.length}',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: EduColors.textPrimary,
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      HoverCard(child: GestureDetector(
                        onTap: () =>
                            context.read<QuizAdminController>().loadQuizzes(),
                        child: Container(
                          width: 38,
                          height: 38,
                          decoration: BoxDecoration(
                            color: EduColors.primarySoft,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.refresh_rounded,
                            color: EduColors.primary,
                            size: 19,
                          ),
                        ),
                      )),
                      const SizedBox(width: 10),
                      HoverCard(child: GestureDetector(
                        onTap: _createQuiz,
                        child: Container(
                          width: 38,
                          height: 38,
                          decoration: const BoxDecoration(
                            color: EduColors.primary,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.add,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                      )),
                    ],
                  ),
                ],
              ),
            )),
            const SizedBox(height: 8),
            Expanded(
              child: Consumer<QuizAdminController>(
                builder: (context, controller, _) {
                  if (controller.isLoading && controller.quizzes.isEmpty) {
                    return const Center(
                      child: CircularProgressIndicator(color: EduColors.primary),
                    );
                  }
                  if (controller.errorMessage != null &&
                      controller.quizzes.isEmpty) {
                    return _ErrorState(
                      message: controller.errorMessage!,
                      onRetry: () => controller.loadQuizzes(),
                    );
                  }
                  if (controller.quizzes.isEmpty) {
                    return const _EmptyState();
                  }
                  return RefreshIndicator(
                    color: EduColors.primary,
                    onRefresh: controller.loadQuizzes,
                    child: !context.isMobile
                        ? _wideQuizList(controller)
                        : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                      itemCount: controller.quizzes.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        final quiz = controller.quizzes[index];
                        return _QuizTile(
                          quiz: quiz,
                          onTap: () => _openQuiz(controller, quiz),
                          onDelete: () => _deleteQuiz(controller, quiz),
                        );
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ),
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
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: EduColors.border),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: EduColors.primarySoft,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.quiz_rounded,
                  color: EduColors.primary,
                  size: 19,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      quiz.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 14.5,
                        color: EduColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '${quiz.questionCount} question${quiz.questionCount == 1 ? '' : 's'} · ${quiz.totalPoints} points',
                      style: TextStyle(
                        color: EduColors.textSecondary,
                        fontSize: 12.5,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(
                  Icons.delete_outline,
                  color: EduColors.textSecondary,
                  size: 20,
                ),
                onPressed: () => _confirmDeleteQuiz(context, quiz, onDelete),
              ),
            ],
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
            Icon(Icons.quiz_outlined, size: 56, color: EduColors.border),
            const SizedBox(height: 16),
            const Text(
              'No quizzes yet',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: EduColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Tap the + button to build your first assessment.',
              textAlign: TextAlign.center,
              style: TextStyle(color: EduColors.textSecondary),
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
            Icon(Icons.cloud_off, size: 56, color: EduColors.border),
            const SizedBox(height: 16),
            const Text(
              'Could not reach the server',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: EduColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(color: EduColors.textSecondary),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: EduColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
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

/// Asks before deleting a quiz; used by the card list and the desktop table.
void _confirmDeleteQuiz(BuildContext context, Quiz quiz, VoidCallback onDelete) {
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      title: const Text('Delete quiz?'),
      content: Text(
        '"${quiz.title}" and all its questions will be removed.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text(
            'Cancel',
            style: TextStyle(color: EduColors.textSecondary),
          ),
        ),
        TextButton(
          onPressed: () {
            Navigator.pop(context);
            onDelete();
          },
          child: const Text(
            'Delete',
            style: TextStyle(
              color: EduColors.danger,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    ),
    );
}
