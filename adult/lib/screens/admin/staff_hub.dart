import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:adult/Controller/auth_controller.dart';
import 'package:adult/screens/alerts_screen.dart';
import 'package:adult/screens/color.dart';
import 'package:adult/screens/lms_widgets.dart';
import 'package:adult/screens/messages_screen.dart';
import 'package:adult/screens/profile_screen.dart';
import 'package:adult/service/lms_api.dart';
import 'assignments_manage_screen.dart';
import 'attendance_screen.dart';
import 'courses_manage_screen.dart';
import 'reports_screen.dart';
import 'users_screen.dart';

/// "More" tab for admins and instructors: reports, courses, grading,
/// attendance, messages and (admins only) user accounts.
class StaffHub extends StatefulWidget {
  const StaffHub({super.key});

  @override
  State<StaffHub> createState() => _StaffHubState();
}

class _StaffHubState extends State<StaffHub> {
  int _unreadMessages = 0;
  int _unreadAlerts = 0;

  @override
  void initState() {
    super.initState();
    _refreshCounts();
  }

  Future<void> _refreshCounts() async {
    try {
      final r = await Future.wait([LmsApi.get('/messages/unread-count'), LmsApi.get('/notifications/unread-count')]);
      if (!mounted) return;
      setState(() {
        _unreadMessages = (r[0]['count'] as num).toInt();
        _unreadAlerts = (r[1]['count'] as num).toInt();
      });
    } catch (_) {}
  }

  Future<void> _go(Widget screen) async {
    await Navigator.push(context, MaterialPageRoute(builder: (_) => screen));
    _refreshCounts();
  }

  @override
  Widget build(BuildContext context) {
    final role = context.watch<AuthController>().role;
    final isAdmin = role == 'ADMIN' || role == 'INSTITUTION';
    return LmsPage(
      title: 'More',
      body: RefreshIndicator(
        onRefresh: _refreshCounts,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            HubTile(
              icon: Icons.insights_rounded,
              label: 'Reports & monitoring',
              caption: 'Performance, completion rates, participation',
              color: EduColors.success,
              onTap: () => _go(const ReportsScreen()),
            ),
            HubTile(
              icon: Icons.assignment_rounded,
              label: 'Assessments & grading',
              caption: 'Set assignments and tests, grade with feedback',
              color: EduColors.accent,
              onTap: () => _go(const AssignmentsManageScreen()),
            ),
            HubTile(
              icon: Icons.how_to_reg_rounded,
              label: 'Attendance',
              caption: 'Take the register for a course',
              onTap: () => _go(const AttendanceScreen()),
            ),
            HubTile(
              icon: Icons.menu_book_rounded,
              label: 'Courses',
              caption: 'Create, edit and archive courses',
              onTap: () => _go(const CoursesManageScreen()),
            ),
            HubTile(
              icon: Icons.chat_rounded,
              label: 'Messages',
              caption: 'Talk with learners',
              badge: _unreadMessages,
              onTap: () => _go(const MessagesScreen()),
            ),
            HubTile(
              icon: Icons.notifications_rounded,
              label: 'Alerts',
              badge: _unreadAlerts,
              color: EduColors.danger,
              onTap: () => _go(const AlertsScreen()),
            ),
            if (isAdmin)
              HubTile(
                icon: Icons.manage_accounts_rounded,
                label: 'Users',
                caption: 'Accounts, roles and access',
                color: EduColors.primaryDark,
                onTap: () => _go(const UsersScreen()),
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
