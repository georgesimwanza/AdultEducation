import 'package:flutter/material.dart';

import 'package:adult/Model/lms_models.dart';
import 'package:adult/screens/color.dart';
import 'package:adult/screens/lms_widgets.dart';
import 'package:adult/service/lms_api.dart';

/// Create, edit and archive courses. Archiving hides a course from the
/// learner catalogue but keeps everyone's progress and grades.
class CoursesManageScreen extends StatefulWidget {
  const CoursesManageScreen({super.key});

  @override
  State<CoursesManageScreen> createState() => _CoursesManageScreenState();
}

class _CoursesManageScreenState extends State<CoursesManageScreen> {
  final _view = GlobalKey<AsyncViewState<List<CourseSummary>>>();

  Future<void> _edit([CourseSummary? course]) async {
    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _CourseSheet(course: course),
    );
    if (saved == true) _view.currentState?.reload();
  }

  Future<void> _toggle(CourseSummary c) async {
    try {
      await LmsApi.patch('/course/manage/${c.id}/status', {'active': !c.isActive});
      if (mounted) showMessage(context, c.isActive ? '${c.name} archived' : '${c.name} reopened');
      _view.currentState?.reload();
    } catch (e) {
      if (mounted) showError(context, e);
    }
  }

  @override
  Widget build(BuildContext context) {
    return LmsPage(
      title: 'Courses',
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _edit(),
        backgroundColor: EduColors.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: const Text('New course'),
      ),
      body: AsyncView<List<CourseSummary>>(
        key: _view,
        load: () async => ((await LmsApi.get('/course/manage')) as List).map((e) => CourseSummary.fromJson(e)).toList(),
        builder: (context, list, reload) {
          if (list.isEmpty) return const EmptyState(icon: Icons.menu_book_rounded, title: 'No courses yet');
          final sorted = [...list]..sort((a, b) => a.isActive == b.isActive ? a.name.compareTo(b.name) : (a.isActive ? -1 : 1));
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 90),
            children: [
              for (final c in sorted)
                LmsCard(
                  onTap: () => _edit(c),
                  child: Row(children: [
                    Expanded(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(c.name,
                            style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                color: c.isActive ? EduColors.textPrimary : EduColors.textSecondary)),
                        Text(
                          [c.courseCode, if (c.level != null) c.level!, '${c.lessonCount} lessons', '${c.credits} credits']
                              .join(' · '),
                          style: const TextStyle(color: EduColors.textSecondary),
                        ),
                        if (!c.isActive) ...[
                          const SizedBox(height: 4),
                          const StatusChip('Archived', color: EduColors.textSecondary),
                        ],
                      ]),
                    ),
                    IconButton(
                      tooltip: c.isActive ? 'Archive' : 'Reopen',
                      icon: Icon(c.isActive ? Icons.archive_outlined : Icons.unarchive_outlined),
                      onPressed: () => _toggle(c),
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

class _CourseSheet extends StatefulWidget {
  final CourseSummary? course;
  const _CourseSheet({this.course});

  @override
  State<_CourseSheet> createState() => _CourseSheetState();
}

class _CourseSheetState extends State<_CourseSheet> {
  final _form = GlobalKey<FormState>();
  late final _code = TextEditingController(text: widget.course?.courseCode ?? '');
  late final _name = TextEditingController(text: widget.course?.name ?? '');
  late final _description = TextEditingController(text: widget.course?.description ?? '');
  late final _category = TextEditingController(text: widget.course?.category ?? '');
  late final _level = TextEditingController(text: widget.course?.level ?? '');
  late final _credits = TextEditingController(text: '${widget.course?.credits ?? 1}');
  int? _programmeId;
  List<Map<String, dynamic>> _programmes = [];
  bool _busy = false;

  bool get _isNew => widget.course == null;

  @override
  void initState() {
    super.initState();
    if (_isNew) {
      LmsApi.get('/programmes/allProgrammes').then((list) {
        if (mounted) setState(() => _programmes = (list as List).cast<Map<String, dynamic>>());
      }).catchError((_) {});
    }
  }

  @override
  void dispose() {
    for (final c in [_code, _name, _description, _category, _level, _credits]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    setState(() => _busy = true);
    final body = {
      'courseCode': _code.text.trim(),
      'name': _name.text.trim(),
      'description': _description.text.trim(),
      'category': _category.text.trim(),
      'level': _level.text.trim(),
      'credits': int.tryParse(_credits.text) ?? 1,
      if (_isNew && _programmeId != null) 'programmeId': _programmeId,
    };
    try {
      if (_isNew) {
        await LmsApi.post('/course/manage', body);
      } else {
        await LmsApi.put('/course/manage/${widget.course!.id}', body);
      }
      if (mounted) {
        showMessage(context, _isNew ? 'Course created' : 'Course updated');
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
            Text(_isNew ? 'New course' : 'Edit course',
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
            const SizedBox(height: 14),
            TextFormField(
              controller: _code,
              textCapitalization: TextCapitalization.characters,
              decoration: deco('Course code (e.g. DL-101)'),
              validator: (v) => (v ?? '').trim().isEmpty ? 'Required' : null,
            ),
            const SizedBox(height: 10),
            TextFormField(
              controller: _name,
              decoration: deco('Course name'),
              validator: (v) => (v ?? '').trim().isEmpty ? 'Required' : null,
            ),
            const SizedBox(height: 10),
            TextFormField(controller: _description, maxLines: 3, decoration: deco('Description')),
            const SizedBox(height: 10),
            Row(children: [
              Expanded(child: TextFormField(controller: _category, decoration: deco('Category'))),
              const SizedBox(width: 10),
              Expanded(child: TextFormField(controller: _level, decoration: deco('Level'))),
            ]),
            const SizedBox(height: 10),
            TextFormField(controller: _credits, keyboardType: TextInputType.number, decoration: deco('Credits')),
            if (_isNew && _programmes.isNotEmpty) ...[
              const SizedBox(height: 10),
              DropdownButtonFormField<int>(
                initialValue: _programmeId,
                isExpanded: true,
                decoration: deco('Add to programme (optional)'),
                items: [
                  for (final p in _programmes)
                    DropdownMenuItem(value: (p['id'] as num).toInt(), child: Text(p['name'] ?? '')),
                ],
                onChanged: (v) => setState(() => _programmeId = v),
              ),
              const Padding(
                padding: EdgeInsets.only(top: 6),
                child: Text("The programme's learners will be enrolled automatically.",
                    style: TextStyle(color: EduColors.textSecondary)),
              ),
            ],
            const SizedBox(height: 18),
            BigButton(label: _isNew ? 'Create course' : 'Save changes', busy: _busy, onPressed: _save),
          ]),
        ),
      ),
    );
  }
}
