import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:adult/Model/lms_models.dart';
import 'package:adult/screens/color.dart';
import 'package:adult/screens/lms_widgets.dart';
import 'package:adult/screens/progress_report_screen.dart';
import 'package:adult/service/lms_api.dart';

/// Staff reports: overview dashboard, course performance & completion
/// rates, and learner participation monitoring.
class ReportsScreen extends StatelessWidget {
  const ReportsScreen({super.key});

  Future<void> _export(BuildContext context, String path, String what) async {
    try {
      final csv = await LmsApi.getText(path);
      await Clipboard.setData(ClipboardData(text: csv));
      if (context.mounted) {
        showMessage(context, '$what copied as CSV. Paste it into Excel or Google Sheets.');
      }
    } catch (e) {
      if (context.mounted) showError(context, e);
    }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Builder(builder: (context) {
        return LmsPage(
          title: 'Reports',
          actions: [
            PopupMenuButton<String>(
              tooltip: 'Export',
              icon: const Icon(Icons.download_rounded),
              onSelected: (v) => v == 'courses'
                  ? _export(context, '/reports/courses.csv', 'Course report')
                  : _export(context, '/reports/participation.csv', 'Participation report'),
              itemBuilder: (_) => const [
                PopupMenuItem(value: 'courses', child: Text('Export course report (CSV)')),
                PopupMenuItem(value: 'participation', child: Text('Export participation report (CSV)')),
              ],
            ),
          ],
          bottom: const TabBar(
            labelStyle: TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
            tabs: [Tab(text: 'Overview'), Tab(text: 'Courses'), Tab(text: 'Learners')],
          ),
          body: const TabBarView(children: [_Overview(), _Courses(), _Participation()]),
        );
      }),
    );
  }
}

class _Overview extends StatelessWidget {
  const _Overview();

  @override
  Widget build(BuildContext context) {
    return AsyncView<AdminDashboardData>(
      load: () async => AdminDashboardData.fromJson(await LmsApi.get('/reports/dashboard/admin')),
      builder: (context, d, reload) => ListView(
        padding: const EdgeInsets.all(16),
        children: [
          StatGrid(tiles: [
            StatTile(label: 'Learners', value: '${d.totalLearners}', icon: Icons.people_rounded),
            StatTile(
                label: 'Active in last 7 days',
                value: '${d.activeLearnersLast7Days}',
                icon: Icons.bolt_rounded,
                color: EduColors.accent),
            StatTile(
                label: 'Instructors', value: '${d.totalInstructors}', icon: Icons.co_present_rounded),
            StatTile(label: 'Courses running', value: '${d.totalCourses}', icon: Icons.menu_book_rounded),
            StatTile(
                label: 'Completion rate',
                value: '${d.completionRate}%',
                icon: Icons.emoji_events_rounded,
                color: EduColors.success),
            StatTile(
                label: 'Average progress',
                value: '${d.averageProgress}%',
                icon: Icons.trending_up_rounded,
                color: EduColors.success),
            StatTile(
                label: 'Waiting to be graded',
                value: '${d.pendingGrading}',
                icon: Icons.pending_actions_rounded,
                color: EduColors.danger),
            StatTile(
                label: 'Deadlines this week',
                value: '${d.upcomingDeadlines}',
                icon: Icons.alarm_rounded,
                color: EduColors.accent),
          ]),
          const SectionTitle('Learners needing attention'),
          if (d.learnersNeedingAttention.isEmpty)
            const Text('Everyone is active. 🎉', style: TextStyle(fontSize: 15)),
          for (final p in d.learnersNeedingAttention) _ParticipationCard(p: p),
        ],
      ),
    );
  }
}

class _Courses extends StatelessWidget {
  const _Courses();

  @override
  Widget build(BuildContext context) {
    return AsyncView<List<CourseStats>>(
      load: () async => ((await LmsApi.get('/reports/courses')) as List).map((e) => CourseStats.fromJson(e)).toList(),
      builder: (context, list, reload) {
        if (list.isEmpty) return const EmptyState(icon: Icons.bar_chart_rounded, title: 'No enrollments yet');
        String pct(int? v) => v == null ? '—' : '$v%';
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            for (final c in list)
              LmsCard(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(c.courseName, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
                  Text('${c.courseCode} · ${c.enrolled} enrolled · ${c.completed} completed',
                      style: const TextStyle(color: EduColors.textSecondary)),
                  const SizedBox(height: 10),
                  ProgressLine(percent: c.completionRate, label: 'Completion rate', color: EduColors.success),
                  const SizedBox(height: 8),
                  ProgressLine(percent: c.averageProgress, label: 'Average progress'),
                  const SizedBox(height: 10),
                  Wrap(spacing: 8, runSpacing: 6, children: [
                    StatusChip('Quiz avg ${pct(c.averageQuizScore)}', color: EduColors.accent),
                    StatusChip('Assignment avg ${pct(c.averageAssignmentPercent)}', color: EduColors.primary),
                    StatusChip('Attendance ${pct(c.attendanceRate)}', color: EduColors.success),
                  ]),
                ]),
              ),
          ],
        );
      },
    );
  }
}

class _Participation extends StatelessWidget {
  const _Participation();

  @override
  Widget build(BuildContext context) {
    return AsyncView<List<ParticipationLine>>(
      load: () async =>
          ((await LmsApi.get('/reports/participation')) as List).map((e) => ParticipationLine.fromJson(e)).toList(),
      builder: (context, list, reload) {
        if (list.isEmpty) return const EmptyState(icon: Icons.groups_rounded, title: 'No learners yet');
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [for (final p in list) _ParticipationCard(p: p)],
        );
      },
    );
  }
}

class _ParticipationCard extends StatelessWidget {
  final ParticipationLine p;
  const _ParticipationCard({required this.p});

  @override
  Widget build(BuildContext context) {
    final color = switch (p.status) {
      'Inactive' => EduColors.danger,
      'At risk' => EduColors.accent,
      _ => EduColors.success,
    };
    return LmsCard(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => ProgressReportScreen(learnerId: p.learnerId)),
      ),
      child: Row(children: [
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(p.name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
            Text(
              'Last active ${p.lastActive == null ? 'never' : relativeTime(p.lastActive!)} · '
              '${p.eventsLast30Days} actions in 30 days',
              style: const TextStyle(fontSize: 13, color: EduColors.textSecondary),
            ),
            Text(
              'Progress ${p.averageProgress}% · attendance ${p.attendanceRate == null ? '—' : '${p.attendanceRate}%'}',
              style: const TextStyle(fontSize: 13, color: EduColors.textSecondary),
            ),
          ]),
        ),
        StatusChip(p.status, color: color),
      ]),
    );
  }
}
