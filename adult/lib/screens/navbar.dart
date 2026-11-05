import 'package:adult/core/app_nav_shell.dart';
import 'package:adult/screens/noticeboard.dart';
import 'package:flutter/material.dart';
import 'dashboard.dart';
import 'learning_hub.dart';

import 'notification.dart';
import 'schedule_screen.dart';

class StudentNavBar extends StatelessWidget {
  const StudentNavBar({super.key});

  // Icon pairs: outlined when inactive, filled when active.
  static const List<NavDestination> _items = [
    NavDestination(
      label: 'Home',
      icon: Icons.home_outlined,
      activeIcon: Icons.home_rounded,
    ),
    NavDestination(
      label: 'Learn',
      icon: Icons.school_outlined,
      activeIcon: Icons.school_rounded,
    ),
    NavDestination(
      label: 'Schedule',
      icon: Icons.calendar_month_outlined,
      activeIcon: Icons.calendar_month_rounded,
    ),
    NavDestination(
      label: 'Notices',
      icon: Icons.campaign_outlined,
      activeIcon: Icons.campaign_rounded,
    ),
    NavDestination(
      label: 'Settings',
      icon: Icons.settings_outlined,
      activeIcon: Icons.settings_rounded,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return AppNavShell(
      destinations: _items,
      screens: const [
        Dashboard(),
        LearningHub(),
        ScheduleScreen(),
        NoticeBoardScreen(),
        NotificationPage(),
      ],
    );
  }
}
