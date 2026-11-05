import 'package:flutter/material.dart';

import 'package:adult/Model/lms_models.dart';
import 'package:adult/screens/color.dart';
import 'package:adult/screens/lms_widgets.dart';
import 'package:adult/service/lms_api.dart';

/// A learner's progress report: courses, grades with feedback, attendance
/// and activity. Learners see their own; staff pass [learnerId].
class ProgressReportScreen extends StatelessWidget {
  final int? learnerId;
  const ProgressReportScreen({super.key, this.learnerId});

  @override
  Widget build(BuildContext context) {
    return LmsPage(
      title: learnerId == null ? 'My Progress Report' : 'Learner Report',
      body: AsyncView<LearnerReport>(
        load: () async => LearnerReport.fromJson(
            await LmsApi.get(learnerId == null ? '/reports/me' : '/reports/learner/$learnerId')),
        builder: (context, r, reload) => ListView(
          padding: const EdgeInsets.all(16),
          children: [
            LmsCard(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(r.name, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
                Text(r.email, style: const TextStyle(color: EduColors.textSecondary)),
                const SizedBox(height: 6),
                Wrap(spacing: 6, runSpacing: 4, children: [
                  if (r.programmeName != null) StatusChip(r.programmeName!, color: EduColors.primary),
                  if (r.educationLevel != null) StatusChip(r.educationLevel!, color: EduColors.accent),
                ]),
                const SizedBox(height: 6),
                Text('Report made ${formatDateTime(r.generatedAt)}',
                    style: const TextStyle(fontSize: 12.5, color: EduColors.textSecondary)),
              ]),
            ),
            StatGrid(tiles: [
              StatTile(label: 'Average progress', value: '${r.averageProgress}%', icon: Icons.trending_up_rounded),
              StatTile(
                  label: 'Courses completed',
                  value: '${r.completedCourses} of ${r.courses.length}',
                  icon: Icons.emoji_events_rounded,
                  color: EduColors.success),
              StatTile(
                  label: 'Average quiz score',
                  value: r.averageQuizScore == null ? '—' : '${r.averageQuizScore}%',
                  icon: Icons.quiz_rounded,
                  color: EduColors.accent),
              StatTile(
                  label: 'Average assignment mark',
                  value: r.averageAssignmentPercent == null ? '—' : '${r.averageAssignmentPercent}%',
                  icon: Icons.assignment_rounded),
              StatTile(
                  label: 'Attendance',
                  value: r.attendanceRate == null ? '—' : '${r.attendanceRate}%',
                  icon: Icons.how_to_reg_rounded,
                  color: EduColors.success),
              StatTile(
                  label: 'Activity (last 30 days)',
                  value: '${r.activityLast30Days}',
                  icon: Icons.bolt_rounded,
                  color: EduColors.accent),
            ]),
            const SectionTitle('Courses'),
            if (r.courses.isEmpty) const Text('Not enrolled in any courses yet.'),
            for (final c in r.courses)
              LmsCard(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(c.courseName, style: const TextStyle(fontSize: 15.5, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 8),
                  ProgressLine(
                    percent: c.progressPercentage,
                    label: c.status == 'COMPLETED' ? 'Completed ${formatDate(c.completedAt)}' : 'In progress',
                  ),
                ]),
              ),
            const SectionTitle('Grades & feedback'),
            if (r.grades.isEmpty) const Text('No quizzes or assignments yet.'),
            for (final g in r.grades)
              LmsCard(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [
                    Expanded(
                      child: Text(g.title, style: const TextStyle(fontSize: 15.5, fontWeight: FontWeight.w800)),
                    ),
                    g.score == null
                        ? const StatusChip('Waiting for grade', color: EduColors.textSecondary)
                        : StatusChip(
                            g.kind == 'QUIZ' ? '${g.score}%' : '${g.score}/${g.maxScore}',
                            color: (g.percent ?? 0) >= 50 ? EduColors.success : EduColors.danger,
                          ),
                  ]),
                  Text(
                    '${switch (g.kind) { 'QUIZ' => 'Quiz', 'TEST' => 'Test', _ => 'Assignment' }}'
                    '${g.courseName != null ? ' · ${g.courseName}' : ''} · ${formatDate(g.date)}',
                    style: const TextStyle(fontSize: 13, color: EduColors.textSecondary),
                  ),
                  if (g.feedback != null && g.feedback!.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text('“${g.feedback}”', style: const TextStyle(fontStyle: FontStyle.italic)),
                  ],
                ]),
              ),
            const SectionTitle('Attendance'),
            if (r.attendance.isEmpty) const Text('No attendance recorded yet.'),
            for (final a in r.attendance.take(30))
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(
                  a.status == 'ABSENT' ? Icons.cancel_rounded : Icons.check_circle_rounded,
                  color: a.status == 'ABSENT' ? EduColors.danger : EduColors.success,
                ),
                title: Text(a.courseName),
                subtitle: Text(
                    '${formatDate(a.date)}${a.source == 'AUTO' ? ' · watched a video lesson' : ''}'),
                trailing: Text(a.status[0] + a.status.substring(1).toLowerCase(),
                    style: const TextStyle(fontWeight: FontWeight.w700)),
              ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
