import 'package:adult/screens/noticeboard.dart';
import 'package:flutter/material.dart';
import 'dashboard.dart';
import 'coursepage.dart';

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _selectedIndex, children: _screens),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (i) => setState(() => _selectedIndex = i),
        backgroundColor: const Color(0xFFFFFFFF),
        selectedItemColor: Colors.black,
        unselectedItemColor: Colors.black,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard_rounded),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_month_rounded),
            label: 'Schedule',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.message_rounded),
            label: 'NoticePage',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.notifications_rounded),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}
