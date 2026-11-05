import 'package:adult/Controller/auth_controller.dart';
import 'package:adult/core/app_nav_shell.dart';
import 'package:adult/screens/notification.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'quiz_screen.dart';
import 'content_screen.dart';
import 'dashboard_screen.dart';
import 'students_screen.dart';
import 'announcement_screen.dart';
import 'staff_hub.dart';

/// Admin and instructor navigation: same frame and look as the student app,
/// a "More" hub (reports, grading, attendance, courses, messages, users),
/// and the shared Settings page (profile, account details and logout).
class AdminNavBar extends StatelessWidget {
  const AdminNavBar({super.key});

  static const List<NavDestination> _items = [
    NavDestination(
      label: 'Home',
      icon: Icons.dashboard_outlined,
      activeIcon: Icons.dashboard_rounded,
    ),
    NavDestination(
      label: 'Students',
      icon: Icons.people_outline_rounded,
      activeIcon: Icons.people_rounded,
    ),
    NavDestination(
      label: 'Notices',
      icon: Icons.campaign_outlined,
      activeIcon: Icons.campaign_rounded,
    ),
    NavDestination(
      label: 'Content',
      icon: Icons.folder_outlined,
      activeIcon: Icons.folder_rounded,
    ),
    NavDestination(
      label: 'Quizzes',
      icon: Icons.quiz_outlined,
      activeIcon: Icons.quiz_rounded,
    ),
    NavDestination(
      label: 'More',
      icon: Icons.apps_outlined,
      activeIcon: Icons.apps_rounded,
    ),
    NavDestination(
      label: 'Settings',
      icon: Icons.settings_outlined,
      activeIcon: Icons.settings_rounded,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final role = context.watch<AuthController>().role;
    return AppNavShell(
      subtitle: role == 'INSTRUCTOR' ? 'Instructor' : 'Admin',
      destinations: _items,
      screens: const [
        DashboardScreen(),
        StudentsScreen(),
        AnnouncementsScreen(),
        ContentScreen(),
        QuizScreen(),
        StaffHub(),
        NotificationPage(),
      ],
    );
  }
}
