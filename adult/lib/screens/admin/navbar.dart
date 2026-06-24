import 'package:adult/service/contentService.dart';
import 'package:flutter/material.dart';
import 'admins_screen.dart';
import 'content_screen.dart';
import 'dashboard_screen.dart';
import 'students_screen.dart';
import 'subjects_screen.dart';

class AdminNavBar extends StatefulWidget {
  const AdminNavBar({super.key});

  @override
  State<AdminNavBar> createState() => _MyNavBarState();
}

class _MyNavBarState extends State<AdminNavBar> {
  int _selectedIndex = 0;

  final List<Widget> _screens = [
    // fix 1: List<Widget> not List<NavBar>
    DashboardScreen(),
    StudentsScreen(),
    SubjectsScreen(),
    ContentScreen(),
    AdminsScreen(),
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
            label: 'Students',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.book_rounded),
            label: 'Subjects',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.folder_rounded),
            label: 'Content',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.admin_panel_settings_rounded),
            label: 'Admins',
          ),
        ],
      ),
    );
  }
}
