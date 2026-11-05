import 'package:flutter/material.dart';

import 'package:adult/Model/lms_models.dart';
import 'package:adult/screens/alerts_screen.dart';
import 'package:adult/screens/assignments_screen.dart';
import 'package:adult/screens/color.dart';
import 'package:adult/screens/lms_widgets.dart';
import 'package:adult/screens/messages_screen.dart';
import 'package:adult/screens/my_courses_screen.dart';
import 'package:adult/screens/profile_screen.dart';
import 'package:adult/screens/progress_report_screen.dart';
import 'package:adult/service/lms_api.dart';

/// The learner's "My Learning" tab: a short dashboard (progress, what's
/// due, unread alerts and messages) and big buttons into each feature.
class LearningHub extends StatefulWidget {
  const LearningHub({super.key});

  @override
  State<LearningHub> createState() => _LearningHubState();
}

class _LearningHubState extends State<LearningHub> {
  final _view = GlobalKey<AsyncViewState<LearnerDashboardData>>();

  Future<void> _go(Widget screen) async {
    await Navigator.push(context, MaterialPageRoute(builder: (_) => screen));
    _view.currentState?.reload();
  }

  @override
  Widget build(BuildContext context) {
    return LmsPage(
      title: 'My Learning',
      body: AsyncView<LearnerDashboardData>(
        key: _view,
        load: () async => LearnerDashboardData.fromJson(await LmsApi.get('/reports/dashboard/learner')),
        builder: (context, d, reload) => ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [EduColors.primary, EduColors.primaryDark]),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('Your progress',
                    style: TextStyle(color: EduColors.onPrimaryMuted, fontWeight: FontWeight.w700)),
                const SizedBox(height: 4),
                Text('${d.averageProgress}%',
                    style: const TextStyle(color: Colors.white, fontSize: 38, fontWeight: FontWeight.w900)),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: d.averageProgress / 100,
                    minHeight: 10,
                    backgroundColor: EduColors.onPrimaryFaint,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  '${d.completedCourses} of ${d.enrolledCourses} courses finished'
                  '${d.attendanceRate != null ? ' · attendance ${d.attendanceRate}%' : ''}',
                  style: const TextStyle(color: Colors.white, fontSize: 14.5),
                ),
              ]),
            ),
            if (d.upcomingDeadlines.isNotEmpty) ...[
              const SectionTitle('Due soon'),
              for (final a in d.upcomingDeadlines.take(3))
                LmsCard(
                  onTap: () => _go(AssignmentDetailScreen(assignment: a)),
                  child: Row(children: [
                    const Icon(Icons.alarm_rounded, color: EduColors.accent),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(a.title, style: const TextStyle(fontWeight: FontWeight.w800)),
                        Text(a.courseName, style: const TextStyle(color: EduColors.textSecondary)),
                      ]),
                    ),
                    StatusChip('Due ${relativeTime(a.dueDate)}', color: EduColors.accent),
                  ]),
                ),
            ],
            if (d.continueLearning.isNotEmpty) ...[
              const SectionTitle('Keep going'),
              for (final e in d.continueLearning)
                LmsCard(
                  onTap: () => _go(const MyCoursesScreen()),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(e.courseName, style: const TextStyle(fontWeight: FontWeight.w800)),
                    const SizedBox(height: 8),
                    ProgressLine(percent: e.progressPercentage),
                  ]),
                ),
            ],
            const SectionTitle('What would you like to do?'),
            HubTile(
              icon: Icons.menu_book_rounded,
              label: 'My courses',
              caption: 'See your courses and join new ones',
              onTap: () => _go(const MyCoursesScreen()),
            ),
            HubTile(
              icon: Icons.assignment_rounded,
              label: 'Assignments & tests',
              caption: 'Hand in work and see your marks',
              badge: d.upcomingDeadlines.length,
              color: EduColors.accent,
              onTap: () => _go(const AssignmentsScreen()),
            ),
            HubTile(
              icon: Icons.chat_rounded,
              label: 'Messages',
              caption: 'Ask your instructor a question',
              badge: d.unreadMessages,
              onTap: () => _go(const MessagesScreen()),
            ),
            HubTile(
              icon: Icons.notifications_rounded,
              label: 'Alerts',
              caption: 'Deadlines, grades and news',
              badge: d.unreadNotifications,
              color: EduColors.danger,
              onTap: () => _go(const AlertsScreen()),
            ),
            HubTile(
              icon: Icons.insights_rounded,
              label: 'My progress report',
              caption: 'Grades, feedback and attendance',
              color: EduColors.success,
              onTap: () => _go(const ProgressReportScreen()),
            ),
            HubTile(
              icon: Icons.person_rounded,
              label: 'My profile',
              caption: 'Your details and text size',
              color: EduColors.textSecondary,
              onTap: () => _go(const ProfileScreen()),
            ),
          ],
        ),
      ),
    );
  }
}
