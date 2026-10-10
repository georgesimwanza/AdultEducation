import 'package:adult/screens/noticeboard.dart';
import 'package:adult/screens/color.dart'; // EduColors
import 'package:flutter/material.dart';
import 'dashboard.dart';

import 'notification.dart';
import 'schedule_screen.dart';

class StudentNavBar extends StatefulWidget {
  const StudentNavBar({super.key});
  @override
  State<StudentNavBar> createState() => _MyNavBarState();
}

class _MyNavBarState extends State<StudentNavBar> {
  int _selectedIndex = 0;

  final List<Widget> _screens = [
    Dashboard(),
    ScheduleScreen(),
    NoticeBoardScreen(),
    NotificationPage(),
  ];

  // Icon pairs: outlined when inactive, filled when active.
  static const List<_NavItemData> _items = [
    _NavItemData(
      label: 'Home',
      icon: Icons.home_outlined,
      activeIcon: Icons.home_rounded,
    ),
    _NavItemData(
      label: 'Schedule',
      icon: Icons.calendar_month_outlined,
      activeIcon: Icons.calendar_month_rounded,
    ),
    _NavItemData(
      label: 'Notices',
      icon: Icons.campaign_outlined,
      activeIcon: Icons.campaign_rounded,
    ),
    _NavItemData(
      label: 'Settings',
      icon: Icons.settings_outlined,
      activeIcon: Icons.settings_rounded,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: EduColors.background,
      body: IndexedStack(index: _selectedIndex, children: _screens),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: EduColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          boxShadow: [
            BoxShadow(
              color: Color(0x1A3D5CFF),
              blurRadius: 24,
              offset: Offset(0, -8),
            ),
          ],
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
            child: Row(
              children: [
                for (int i = 0; i < _items.length; i++)
                  Expanded(
                    child: _NavItem(
                      data: _items[i],
                      selected: i == _selectedIndex,
                      onTap: () => setState(() => _selectedIndex = i),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItemData {
  final String label;
  final IconData icon;
  final IconData activeIcon;

  const _NavItemData({
    required this.label,
    required this.icon,
    required this.activeIcon,
  });
}

class _NavItem extends StatelessWidget {
  final _NavItemData data;
  final bool selected;
  final VoidCallback onTap;

  const _NavItem({
    required this.data,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Pill behind the icon grows in when the tab is active.
          AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
            width: selected ? 60 : 36,
            height: 34,
            decoration: BoxDecoration(
              color: selected ? EduColors.primarySoft : Colors.transparent,
              borderRadius: BorderRadius.circular(17),
            ),
            child: Icon(
              selected ? data.activeIcon : data.icon,
              size: 23,
              color: selected ? EduColors.primary : EduColors.textSecondary,
            ),
          ),
          const SizedBox(height: 4),
          AnimatedDefaultTextStyle(
            duration: const Duration(milliseconds: 200),
            style: TextStyle(
              fontSize: 11,
              fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
              color: selected ? EduColors.primary : EduColors.textSecondary,
            ),
            child: Text(data.label),
          ),
        ],
      ),
    );
  }
}