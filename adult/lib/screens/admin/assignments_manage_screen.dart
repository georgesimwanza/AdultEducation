import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:adult/Model/lms_models.dart';
import 'package:adult/screens/color.dart';
import 'package:adult/screens/lms_widgets.dart';
import 'package:adult/service/lms_api.dart';

/// Staff: set assignments and tests, review what learners handed in, and
/// grade with feedback. The second tab grades quiz attempts.
class AssignmentsManageScreen extends StatelessWidget {
  const AssignmentsManageScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const DefaultTabController(
      length: 2,
      child: LmsPage(
        title: 'Assessments & Grading',
        bottom: TabBar(
          labelStyle: TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
          tabs: [Tab(text: 'Assignments & tests'), Tab(text: 'Quiz attempts')],
        ),
        body: TabBarView(children: [_AssignmentsTab(), _QuizzesTab()]),
      ),
    );
  }
}

// ── Assignments & tests ─────────────────────────────────────────────────

class _AssignmentsTab extends StatefulWidget {
  const _AssignmentsTab();

  @override
  State<_AssignmentsTab> createState() => _AssignmentsTabState();
}

class _AssignmentsTabState extends State<_AssignmentsTab> {
  final _view = GlobalKey<AsyncViewState<List<Assignment>>>();

  Future<void> _edit([Assignment? a]) async {
    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _AssignmentSheet(assignment: a),
    );
    if (saved == true) _view.currentState?.reload();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'new-assignment',
        onPressed: () => _edit(),
        backgroundColor: EduColors.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Set work'),
      ),
      body: AsyncView<List<Assignment>>(
        key: _view,
        load: () async => ((await LmsApi.get('/assignments/manage')) as List).map((e) => Assignment.fromJson(e)).toList(),
        builder: (context, list, reload) {
          if (list.isEmpty) {
            return const EmptyState(
              icon: Icons.assignment_add,
              title: 'No assignments yet',
              message: 'Tap "Set work" to create an assignment or test.',
            );
          }
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 90),
            children: [
              for (final a in list)
                LmsCard(
                  onTap: () async {
                    await Navigator.push(
                        context, MaterialPageRoute(builder: (_) => SubmissionsScreen(assignment: a)));
                    reload();
                  },
                  child: Row(children: [
                    CircleAvatar(
                      backgroundColor: EduColors.primarySoft,
                      child: Icon(a.isTest ? Icons.fact_check_rounded : Icons.edit_note_rounded,
                          color: EduColors.primary),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(a.title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
                        Text('${a.isTest ? 'Test' : 'Assignment'} · ${a.courseName}',
                            style: TextStyle(color: EduColors.textSecondary)),
                        Text('Due ${formatDateTime(a.dueDate)} · ${a.submissionCount} handed in, '
                            '${a.submissionCount - a.gradedCount} to grade',
                            style: TextStyle(fontSize: 13, color: EduColors.textSecondary)),
                      ]),
                    ),
                    PopupMenuButton<String>(
                      onSelected: (v) async {
                        if (v == 'edit') {
                          _edit(a);
                        } else if (v == 'delete') {
                          final ok = await showDialog<bool>(
                            context: context,
                            builder: (d) => AlertDialog(
                              title: const Text('Delete this work?'),
                              content: const Text('All submissions and grades for it will be deleted too.'),
                              actions: [
                                TextButton(onPressed: () => Navigator.pop(d, false), child: const Text('Cancel')),
                                FilledButton(onPressed: () => Navigator.pop(d, true), child: const Text('Delete')),
                              ],
                            ),
                          );
                          if (ok != true) return;
                          try {
                            await LmsApi.delete('/assignments/${a.id}');
                            reload();
                          } catch (e) {
                            if (context.mounted) showError(context, e);
                          }
                        }
                      },
                      itemBuilder: (_) => const [
                        PopupMenuItem(value: 'edit', child: Text('Edit')),
                        PopupMenuItem(value: 'delete', child: Text('Delete')),
                      ],
                    ),
                  ]),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _AssignmentSheet extends StatefulWidget {
  final Assignment? assignment;
  const _AssignmentSheet({this.assignment});

  @override
  State<_AssignmentSheet> createState() => _AssignmentSheetState();
}

class _AssignmentSheetState extends State<_AssignmentSheet> {
  final _form = GlobalKey<FormState>();
  late final _title = TextEditingController(text: widget.assignment?.title ?? '');
  late final _description = TextEditingController(text: widget.assignment?.description ?? '');
  late final _maxScore = TextEditingController(text: '${widget.assignment?.maxScore ?? 100}');
  late String _kind = widget.assignment?.kind ?? 'ASSIGNMENT';
  late int? _courseId = widget.assignment?.courseId;
  late DateTime _due = widget.assignment?.dueDate ?? DateTime.now().add(const Duration(days: 7));
  List<CourseSummary> _courses = [];
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    LmsApi.get('/course/manage').then((list) {
      if (!mounted) return;
      setState(() => _courses =
          (list as List).map((e) => CourseSummary.fromJson(e)).where((c) => c.isActive || c.id == _courseId).toList());
    }).catchError((_) {});
  }

  @override
  void dispose() {
    _title.dispose();
    _description.dispose();
    _maxScore.dispose();
    super.dispose();
  }

  Future<void> _pickDue() async {
    final day = await showDatePicker(
      context: context,
      initialDate: _due,
      firstDate: DateTime.now().subtract(const Duration(days: 1)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (day == null || !mounted) return;
    final time = await showTimePicker(context: context, initialTime: TimeOfDay.fromDateTime(_due));
    setState(() => _due = DateTime(day.year, day.month, day.day, time?.hour ?? 23, time?.minute ?? 59));
  }

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    setState(() => _busy = true);
    final body = {
      'courseId': _courseId,
      'title': _title.text.trim(),
      'description': _description.text.trim(),
      'kind': _kind,
      'dueDate': _due.toIso8601String().split('.').first,
      'maxScore': int.tryParse(_maxScore.text) ?? 100,
    };
    try {
      if (widget.assignment == null) {
        await LmsApi.post('/assignments', body);
      } else {
        await LmsApi.put('/assignments/${widget.assignment!.id}', body);
      }
      if (mounted) {
        showMessage(context, widget.assignment == null ? 'Work set. Learners have been notified.' : 'Saved');
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) showError(context, e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    InputDecoration deco(String label) =>
        InputDecoration(labelText: label, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)));
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(context).viewInsets.bottom + 20),
      child: Form(
        key: _form,
        child: SingleChildScrollView(
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Text(widget.assignment == null ? 'Set new work' : 'Edit work',
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
            const SizedBox(height: 14),
            SegmentedButton<String>(
              segments: const [
                ButtonSegment(value: 'ASSIGNMENT', label: Text('Assignment'), icon: Icon(Icons.edit_note_rounded)),
                ButtonSegment(value: 'TEST', label: Text('Test'), icon: Icon(Icons.fact_check_rounded)),
              ],
              selected: {_kind},
              onSelectionChanged: (s) => setState(() => _kind = s.first),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<int>(
              initialValue: _courseId,
              isExpanded: true,
              decoration: deco('Course'),
              items: [for (final c in _courses) DropdownMenuItem(value: c.id, child: Text(c.name))],
              onChanged: (v) => setState(() => _courseId = v),
              validator: (v) => v == null ? 'Choose a course' : null,
            ),
            const SizedBox(height: 10),
            TextFormField(
              controller: _title,
              decoration: deco('Title'),
              validator: (v) => (v ?? '').trim().isEmpty ? 'Required' : null,
            ),
            const SizedBox(height: 10),
            TextFormField(controller: _description, maxLines: 4, decoration: deco('Instructions for learners')),
            const SizedBox(height: 10),
            Row(children: [
              Expanded(
                child: InkWell(
                  onTap: _pickDue,
                  child: InputDecorator(decoration: deco('Due'), child: Text(formatDateTime(_due))),
                ),
              ),
              const SizedBox(width: 10),
              SizedBox(
                width: 110,
                child: TextFormField(
                  controller: _maxScore,
                  keyboardType: TextInputType.number,
                  decoration: deco('Marks'),
                  validator: (v) => (int.tryParse(v ?? '') ?? 0) > 0 ? null : '> 0',
                ),
              ),
            ]),
            const SizedBox(height: 18),
            BigButton(label: widget.assignment == null ? 'Set work' : 'Save', busy: _busy, onPressed: _save),
          ]),
        ),
      ),
    );
  }
}

class SubmissionsScreen extends StatelessWidget {
  final Assignment assignment;
  const SubmissionsScreen({super.key, required this.assignment});

  @override
  Widget build(BuildContext context) {
    return LmsPage(
      title: assignment.title,
      body: AsyncView<List<Submission>>(
        load: () async => ((await LmsApi.get('/assignments/${assignment.id}/submissions')) as List)
            .map((e) => Submission.fromJson(e))
            .toList(),
        builder: (context, list, reload) {
          if (list.isEmpty) {
            return const EmptyState(icon: Icons.inbox_rounded, title: 'Nothing handed in yet');
          }
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              for (final s in list)
                LmsCard(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Row(children: [
                      Expanded(
                        child: Text(s.learnerName, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
                      ),
                      if (s.isGraded)
                        StatusChip('${s.score}/${s.maxScore}', color: EduColors.success)
                      else
                        const StatusChip('To grade', color: EduColors.accent),
                    ]),
                    Text('Handed in ${formatDateTime(s.submittedAt)}${s.late ? ' · LATE' : ''}',
                        style: TextStyle(fontSize: 13, color: s.late ? EduColors.danger : EduColors.textSecondary)),
                    if (s.answerText != null) ...[
                      const SizedBox(height: 8),
                      Text(s.answerText!, style: const TextStyle(fontSize: 15, height: 1.4)),
                    ],
                    if (s.fileUrl != null)
                      TextButton.icon(
                        onPressed: () async {
                          await Clipboard.setData(ClipboardData(text: s.fileUrl!));
                          if (context.mounted) showMessage(context, 'File link copied. Paste it into your browser.');
                        },
                        icon: const Icon(Icons.attach_file_rounded),
                        label: const Text('Copy link to attached file'),
                      ),
                    if (s.feedback != null && s.feedback!.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text('Feedback: ${s.feedback}', style: const TextStyle(fontStyle: FontStyle.italic)),
                    ],
                    const SizedBox(height: 8),
                    Align(
                      alignment: Alignment.centerRight,
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.grade_rounded),
                        label: Text(s.isGraded ? 'Change grade' : 'Grade'),
                        onPressed: () async {
                          final done = await showGradeDialog(
                            context,
                            title: 'Grade ${s.learnerName}',
                            maxScore: s.maxScore ?? assignment.maxScore,
                            initialScore: s.score,
                            initialFeedback: s.feedback,
                            save: (score, feedback) => LmsApi.put(
                                '/assignments/submissions/${s.id}/grade', {'score': score, 'feedback': feedback}),
                          );
                          if (done) reload();
                        },
                      ),
                    ),
                  ]),
                ),
            ],
          );
        },
      ),
    );
  }
}

/// Score + feedback dialog shared by assignment and quiz grading.
Future<bool> showGradeDialog(
  BuildContext context, {
  required String title,
  required int maxScore,
  int? initialScore,
  String? initialFeedback,
  required Future<dynamic> Function(int score, String feedback) save,
}) async {
  final score = TextEditingController(text: initialScore?.toString() ?? '');
  final feedback = TextEditingController(text: initialFeedback ?? '');
  final result = await showDialog<bool>(
    context: context,
    builder: (ctx) {
      bool busy = false;
      return StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          title: Text(title),
          content: SingleChildScrollView(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              TextField(
                controller: score,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(labelText: 'Score (out of $maxScore)', border: const OutlineInputBorder()),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: feedback,
                minLines: 3,
                maxLines: 6,
                decoration: const InputDecoration(labelText: 'Feedback for the learner', border: OutlineInputBorder()),
              ),
            ]),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
            FilledButton(
              onPressed: busy
                  ? null
                  : () async {
                      final value = int.tryParse(score.text.trim());
                      if (value == null || value < 0 || value > maxScore) {
                        showMessage(ctx, 'Enter a score from 0 to $maxScore', error: true);
                        return;
                      }
                      setState(() => busy = true);
                      try {
                        await save(value, feedback.text.trim());
                        if (ctx.mounted) Navigator.pop(ctx, true);
                      } catch (e) {
                        setState(() => busy = false);
                        if (ctx.mounted) showMessage(ctx, e.toString(), error: true);
                      }
                    },
              child: const Text('Save grade'),
            ),
          ],
        ),
      );
    },
  );
  score.dispose();
  feedback.dispose();
  return result == true;
}

// ── Quiz attempts ───────────────────────────────────────────────────────

class _QuizzesTab extends StatelessWidget {
  const _QuizzesTab();

  @override
  Widget build(BuildContext context) {
    return AsyncView<List<Map<String, dynamic>>>(
      load: () async {
        final me = await LmsApi.get('/profile') as Map<String, dynamic>;
        final inst = me['institutionId'];
        final list = await LmsApi.get('/quizzes${inst != null ? '?institutionId=$inst' : ''}') as List;
        return list.cast<Map<String, dynamic>>();
      },
      builder: (context, quizzes, reload) {
        if (quizzes.isEmpty) {
          return const EmptyState(icon: Icons.quiz_rounded, title: 'No quizzes yet');
        }
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            for (final q in quizzes)
              LmsCard(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => _QuizAttemptsScreen(quizId: (q['id'] as num).toInt(), title: q['title'] ?? 'Quiz'),
                  ),
                ),
                child: Row(children: [
                  const Icon(Icons.quiz_rounded, color: EduColors.primary),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(q['title'] ?? 'Quiz', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
                  ),
                  const Icon(Icons.chevron_right_rounded),
                ]),
              ),
          ],
        );
      },
    );
  }
}

class _QuizAttemptsScreen extends StatelessWidget {
  final int quizId;
  final String title;
  const _QuizAttemptsScreen({required this.quizId, required this.title});

  @override
  Widget build(BuildContext context) {
    return LmsPage(
      title: title,
      body: AsyncView<List<QuizAttempt>>(
        load: () async => ((await LmsApi.get('/quiz-grading/$quizId/submissions')) as List)
            .map((e) => QuizAttempt.fromJson(e))
            .toList(),
        builder: (context, list, reload) {
          if (list.isEmpty) return const EmptyState(icon: Icons.inbox_rounded, title: 'No attempts yet');
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              for (final a in list)
                LmsCard(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Row(children: [
                      Expanded(
                        child: Text(a.studentName ?? a.studentEmail ?? '',
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
                      ),
                      StatusChip(a.score == null ? 'No score' : '${a.score}%',
                          color: (a.score ?? 0) >= 50 ? EduColors.success : EduColors.danger),
                    ]),
                    Text('Submitted ${formatDateTime(a.submittedAt)}'
                        '${a.gradedAt != null ? ' · reviewed ${formatDate(a.gradedAt)}' : ''}',
                        style: TextStyle(fontSize: 13, color: EduColors.textSecondary)),
                    if (a.feedback != null && a.feedback!.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text('Feedback: ${a.feedback}', style: const TextStyle(fontStyle: FontStyle.italic)),
                    ],
                    Align(
                      alignment: Alignment.centerRight,
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.rate_review_rounded),
                        label: const Text('Review & give feedback'),
                        onPressed: () async {
                          final done = await showGradeDialog(
                            context,
                            title: 'Review attempt',
                            maxScore: 100,
                            initialScore: a.score,
                            initialFeedback: a.feedback,
                            save: (score, feedback) => LmsApi.put(
                                '/quiz-grading/submissions/${a.id}', {'score': score, 'feedback': feedback}),
                          );
                          if (done) reload();
                        },
                      ),
                    ),
                  ]),
                ),
            ],
          );
        },
      ),
    );
  }
}
