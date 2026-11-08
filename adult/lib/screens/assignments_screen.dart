import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';

import 'package:adult/Model/lms_models.dart';
import 'package:adult/screens/color.dart';
import 'package:adult/screens/lms_widgets.dart';
import 'package:adult/service/cdn_supabase.dart';
import 'package:adult/service/lms_api.dart';

/// The learner's assignments and tests: what is due, what was handed in,
/// and grades with the instructor's feedback.
class AssignmentsScreen extends StatelessWidget {
  const AssignmentsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return LmsPage(
      title: 'Assignments & Tests',
      body: AsyncView<List<Assignment>>(
        load: () async => ((await LmsApi.get('/assignments/mine')) as List).map((e) => Assignment.fromJson(e)).toList(),
        builder: (context, list, reload) {
          if (list.isEmpty) {
            return const EmptyState(
              icon: Icons.assignment_turned_in_rounded,
              title: 'Nothing set yet',
              message: 'Work from your instructors will appear here.',
            );
          }
          final todo = list.where((a) => a.mySubmission == null).toList()
            ..sort((a, b) => a.dueDate.compareTo(b.dueDate));
          final waiting = list.where((a) => a.mySubmission != null && !a.mySubmission!.isGraded).toList();
          final graded = list.where((a) => a.mySubmission?.isGraded == true).toList();

          Widget section(String title, List<Assignment> items) => Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SectionTitle('$title (${items.length})'),
                  for (final a in items)
                    _AssignmentCard(
                      a: a,
                      onTap: () async {
                        await Navigator.push(
                            context, MaterialPageRoute(builder: (_) => AssignmentDetailScreen(assignment: a)));
                        reload();
                      },
                    ),
                ],
              );

          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            children: [
              if (todo.isNotEmpty) section('To do', todo),
              if (waiting.isNotEmpty) section('Handed in — waiting for a grade', waiting),
              if (graded.isNotEmpty) section('Graded', graded),
            ],
          );
        },
      ),
    );
  }
}

class _AssignmentCard extends StatelessWidget {
  final Assignment a;
  final VoidCallback onTap;
  const _AssignmentCard({required this.a, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final s = a.mySubmission;
    final Widget chip;
    if (s?.isGraded == true) {
      chip = StatusChip('${s!.score}/${a.maxScore}', color: EduColors.success);
    } else if (s != null) {
      chip = const StatusChip('Handed in', color: EduColors.primary);
    } else if (a.isOverdue) {
      chip = const StatusChip('Late', color: EduColors.danger);
    } else {
      chip = StatusChip('Due ${relativeTime(a.dueDate)}', color: EduColors.accent);
    }
    return LmsCard(
      onTap: onTap,
      child: Row(children: [
        CircleAvatar(
          backgroundColor: EduColors.primarySoft,
          child: Icon(a.isTest ? Icons.fact_check_rounded : Icons.edit_note_rounded, color: EduColors.primary),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(a.title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
            Text('${a.isTest ? 'Test' : 'Assignment'} · ${a.courseName}',
                style: TextStyle(color: EduColors.textSecondary)),
            Text('Due ${formatDateTime(a.dueDate)}', style: TextStyle(fontSize: 13, color: EduColors.textSecondary)),
          ]),
        ),
        const SizedBox(width: 8),
        chip,
      ]),
    );
  }
}

class AssignmentDetailScreen extends StatefulWidget {
  final Assignment assignment;
  const AssignmentDetailScreen({super.key, required this.assignment});

  @override
  State<AssignmentDetailScreen> createState() => _AssignmentDetailScreenState();
}

class _AssignmentDetailScreenState extends State<AssignmentDetailScreen> {
  late final _answer = TextEditingController(text: widget.assignment.mySubmission?.answerText ?? '');
  late String? _fileUrl = widget.assignment.mySubmission?.fileUrl;
  String? _fileName;
  bool _busy = false;
  late Submission? _submission = widget.assignment.mySubmission;

  @override
  void dispose() {
    _answer.dispose();
    super.dispose();
  }

  Future<void> _attach() async {
    final picked = await FilePicker.platform.pickFiles(withData: kIsWeb);
    if (picked == null || picked.files.isEmpty) return;
    setState(() => _busy = true);
    final url = await CdnSupabaseService().uploadContent(picked.files.first, 'submissions/${widget.assignment.id}');
    if (!mounted) return;
    setState(() {
      _busy = false;
      if (url != null) {
        _fileUrl = url;
        _fileName = picked.files.first.name;
      }
    });
    if (url == null) showMessage(context, 'Upload failed. Check your connection and try again.', error: true);
  }

  Future<void> _submit() async {
    setState(() => _busy = true);
    try {
      final res = await LmsApi.post('/assignments/${widget.assignment.id}/submit', {
        'answerText': _answer.text,
        'fileUrl': _fileUrl,
      });
      setState(() => _submission = Submission.fromJson(res));
      if (mounted) showMessage(context, 'Handed in. Your instructor will grade it.');
    } catch (e) {
      if (mounted) showError(context, e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final a = widget.assignment;
    final s = _submission;
    final graded = s?.isGraded == true;
    return LmsPage(
      title: a.isTest ? 'Test' : 'Assignment',
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          LmsCard(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(a.title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
              const SizedBox(height: 4),
              Text(a.courseName, style: TextStyle(color: EduColors.textSecondary)),
              const Divider(height: 24),
              _info(Icons.event_rounded, 'Due', '${formatDateTime(a.dueDate)} (${relativeTime(a.dueDate)})'),
              _info(Icons.star_outline_rounded, 'Marks', 'Out of ${a.maxScore}'),
              if (a.description != null && a.description!.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(a.description!, style: const TextStyle(fontSize: 15.5, height: 1.4)),
              ],
            ]),
          ),
          if (graded)
            LmsCard(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('Your grade', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
                const SizedBox(height: 8),
                Text('${s!.score} / ${a.maxScore}',
                    style: const TextStyle(fontSize: 30, fontWeight: FontWeight.w900, color: EduColors.success)),
                if (s.feedback != null && s.feedback!.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  const Text('Feedback', style: TextStyle(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 4),
                  Text(s.feedback!, style: const TextStyle(fontSize: 15.5, height: 1.4)),
                ],
              ]),
            ),
          const SectionTitle('Your answer'),
          TextField(
            controller: _answer,
            enabled: !graded,
            minLines: 5,
            maxLines: 12,
            decoration: InputDecoration(
              hintText: 'Write your answer here',
              filled: true,
              fillColor: EduColors.surface,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
            ),
          ),
          const SizedBox(height: 12),
          if (_fileUrl != null)
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.attach_file_rounded),
              title: Text(_fileName ?? 'File attached'),
              trailing: graded
                  ? null
                  : IconButton(
                      tooltip: 'Remove file',
                      icon: const Icon(Icons.close_rounded),
                      onPressed: () => setState(() {
                        _fileUrl = null;
                        _fileName = null;
                      }),
                    ),
            ),
          if (!graded) ...[
            OutlinedButton.icon(
              onPressed: _busy ? null : _attach,
              icon: const Icon(Icons.upload_file_rounded),
              label: const Text('Attach a file or photo'),
              style: OutlinedButton.styleFrom(minimumSize: const Size(0, 50)),
            ),
            const SizedBox(height: 16),
            BigButton(
              label: s == null ? 'Hand in' : 'Hand in again',
              icon: Icons.send_rounded,
              busy: _busy,
              onPressed: _submit,
            ),
          ],
          if (s != null) ...[
            const SizedBox(height: 12),
            Text(
              'Handed in ${formatDateTime(s.submittedAt)}${s.late ? ' (late)' : ''}',
              textAlign: TextAlign.center,
              style: TextStyle(color: s.late ? EduColors.danger : EduColors.textSecondary),
            ),
          ],
        ],
      ),
    );
  }

  Widget _info(IconData icon, String label, String value) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Row(children: [
          Icon(icon, size: 20, color: EduColors.textSecondary),
          const SizedBox(width: 8),
          Text('$label: ', style: const TextStyle(fontWeight: FontWeight.w700)),
          Expanded(child: Text(value)),
        ]),
      );
}
