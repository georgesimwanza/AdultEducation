import 'package:flutter/material.dart';
import 'dashboard.dart';
import 'coursepage.dart';
import 'message.dart';
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

    CoursePage(),
    ScheduleScreen(),
    Message(),
    NotificationPage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _selectedIndex, children: _screens),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (i) => setState(() => _selectedIndex = i),
        backgroundColor: const Color(0xFF1A1A1A),
        selectedItemColor: Colors.white,
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard_rounded),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.people_rounded),
            label: 'Subjects',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.book_rounded),
            label: 'Schedule',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.folder_rounded),
            label: 'Messages',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.admin_panel_settings_rounded),
            label: 'Notifications',
          ),
        ],
      ),
    );
  }
}
