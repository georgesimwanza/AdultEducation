import 'package:flutter/material.dart';

import 'package:adult/Model/lms_models.dart';
import 'package:adult/screens/color.dart';
import 'package:adult/screens/lms_widgets.dart';
import 'package:adult/service/lms_api.dart';

/// Attendance register: pick a course and day, tap each learner's status,
/// then save. Learners who watched a video lesson that day are already
/// marked present automatically.
class AttendanceScreen extends StatefulWidget {
  const AttendanceScreen({super.key});

  @override
  State<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends State<AttendanceScreen> {
  static List<(String, String, Color)> get _statuses => [
    ('PRESENT', 'Present', EduColors.success),
    ('LATE', 'Late', EduColors.accent),
    ('ABSENT', 'Absent', EduColors.danger),
    ('EXCUSED', 'Excused', EduColors.textSecondary),
  ];

  List<CourseSummary> _courses = [];
  int? _courseId;
  DateTime _date = DateTime.now();
  List<AttendanceSheetEntry> _sheet = [];
  bool _loading = false;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    LmsApi.get('/course/manage').then((list) {
      if (!mounted) return;
      setState(() => _courses = (list as List).map((e) => CourseSummary.fromJson(e)).where((c) => c.isActive).toList());
    }).catchError((e) {
      if (mounted) setState(() => _error = e.toString());
    });
  }

  String get _dateParam => _date.toIso8601String().substring(0, 10);

  Future<void> _load() async {
    if (_courseId == null) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final list = await LmsApi.get('/attendance/sheet?courseId=$_courseId&date=$_dateParam') as List;
      setState(() => _sheet = list.map((e) => AttendanceSheetEntry.fromJson(e)).toList());
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _save() async {
    final entries = _sheet.where((e) => e.status != null).toList();
    if (entries.isEmpty) {
      showMessage(context, 'Mark at least one learner first', error: true);
      return;
    }
    setState(() => _saving = true);
    try {
      final list = await LmsApi.post('/attendance/mark', {
        'courseId': _courseId,
        'date': _dateParam,
        'entries': [for (final e in entries) {'learnerId': e.learnerId, 'status': e.status}],
      }) as List;
      setState(() => _sheet = list.map((e) => AttendanceSheetEntry.fromJson(e)).toList());
      if (mounted) showMessage(context, 'Attendance saved for ${entries.length} learners');
    } catch (e) {
      if (mounted) showError(context, e);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final marked = _sheet.where((e) => e.status != null).length;
    return LmsPage(
      title: 'Attendance',
      body: Column(children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
          child: Column(children: [
            DropdownButtonFormField<int>(
              initialValue: _courseId,
              isExpanded: true,
              decoration: InputDecoration(
                labelText: 'Course',
                filled: true,
                fillColor: EduColors.surface,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
              ),
              items: [for (final c in _courses) DropdownMenuItem(value: c.id, child: Text(c.name))],
              onChanged: (v) {
                setState(() => _courseId = v);
                _load();
              },
            ),
            const SizedBox(height: 10),
            Row(children: [
              Expanded(
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(minimumSize: const Size(0, 50)),
                  icon: const Icon(Icons.event_rounded),
                  label: Text(formatDate(_date)),
                  onPressed: () async {
                    final d = await showDatePicker(
                      context: context,
                      initialDate: _date,
                      firstDate: DateTime.now().subtract(const Duration(days: 365)),
                      lastDate: DateTime.now(),
                    );
                    if (d != null) {
                      setState(() => _date = d);
                      _load();
                    }
                  },
                ),
              ),
              const SizedBox(width: 10),
              OutlinedButton(
                style: OutlinedButton.styleFrom(minimumSize: const Size(0, 50)),
                onPressed: _sheet.isEmpty
                    ? null
                    : () => setState(() {
                          for (final e in _sheet) {
                            e.status ??= 'PRESENT';
                          }
                        }),
                child: const Text('Rest present'),
              ),
            ]),
          ]),
        ),
        Expanded(
          child: _courseId == null
              ? const EmptyState(icon: Icons.how_to_reg_rounded, title: 'Choose a course to take the register')
              : _loading
                  ? const Center(child: CircularProgressIndicator())
                  : _error != null
                      ? EmptyState(
                          icon: Icons.wifi_off_rounded,
                          title: 'Could not load',
                          message: _error,
                          actionLabel: 'Try again',
                          onAction: _load)
                      : _sheet.isEmpty
                          ? const EmptyState(icon: Icons.groups_rounded, title: 'No learners enrolled in this course')
                          : ListView(
                              padding: const EdgeInsets.all(16),
                              children: [
                                for (final e in _sheet)
                                  LmsCard(
                                    padding: const EdgeInsets.all(12),
                                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                      Row(children: [
                                        Expanded(
                                          child: Text(e.name,
                                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
                                        ),
                                        if (e.source == 'AUTO')
                                          const StatusChip('Watched a lesson', color: EduColors.primary),
                                      ]),
                                      const SizedBox(height: 8),
                                      Wrap(spacing: 6, runSpacing: 6, children: [
                                        for (final (value, label, color) in _statuses)
                                          ChoiceChip(
                                            label: Text(label),
                                            selected: e.status == value,
                                            selectedColor: color.withValues(alpha: 0.2),
                                            onSelected: (_) => setState(() => e.status = value),
                                          ),
                                      ]),
                                    ]),
                                  ),
                              ],
                            ),
        ),
        if (_sheet.isNotEmpty)
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: SizedBox(
                width: double.infinity,
                child: BigButton(
                  label: 'Save register ($marked of ${_sheet.length} marked)',
                  icon: Icons.save_rounded,
                  busy: _saving,
                  onPressed: _save,
                ),
              ),
            ),
          ),
      ]),
    );
  }
}
