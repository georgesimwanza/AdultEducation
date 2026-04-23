import 'package:flutter/material.dart';

class CoursePage extends StatefulWidget {
  const CoursePage({super.key});

  @override
  State<CoursePage> createState() => _CoursePageState();
}

class _CoursePageState extends State<CoursePage> {
  int _selectedTab = 0;

  // ── LESSON DATA ─────────────────────────────────────────
  final List<Map<String, dynamic>> kLessons = [
    {"title": "Introduction to React", "duration": "5:20", "completed": true},
    {"title": "JSX & Components", "duration": "8:10", "completed": true},
    {"title": "State & Props", "duration": "12:00", "completed": false},
    {"title": "Hooks Overview", "duration": "10:30", "completed": false},
  ];

  int get _completedLessons =>
      kLessons.where((lesson) => lesson["completed"] == true).length;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFFFFF),
      body: SafeArea(
        child: Column(
          children: [
            _buildTopBar(),
            _buildCourseInfo(),
            _buildTabBar(),

            // 🔥 SWITCH CONTENT BASED ON TAB
            Expanded(
              child: _selectedTab == 0
                  ? _buildLessonList()
                  : _buildAssignments(),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  // ── TOP BAR ─────────────────────────────────────────────
  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _iconButton(Icons.arrow_back_ios_new_rounded, onTap: () {}),
          const Text(
            'COURSE',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.5,
              color: Color(0xFF111111),
            ),
          ),
          _iconButton(Icons.more_horiz_rounded, onTap: () {}),
        ],
      ),
    );
  }

  Widget _iconButton(IconData icon, {required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: const Color(0xFFF5F5F5),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, size: 17, color: const Color(0xFF111111)),
      ),
    );
  }

  // ── COURSE INFO ─────────────────────────────────────────
  Widget _buildCourseInfo() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
      child: Column(
        children: [
          const Text(
            'React Complete Course',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color.fromARGB(255, 0, 0, 0),
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Basic guideline & tips & tricks for how to become\na React Developer easily.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12, color: Colors.black),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
              CircleAvatar(
                radius: 16,
                backgroundColor: Colors.white,
                child: Icon(
                  Icons.person,
                  size: 18,
                  color: Color.fromARGB(0, 0, 0, 0),
                ),
              ),
              Text(
                '105 Videos',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
              ),
            ],
          ),
          const SizedBox(height: 14),
        ],
      ),
    );
  }

  // ── TAB BAR ─────────────────────────────────────────────
  Widget _buildTabBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: const Color(0xFFF5F5F5),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            _tabItem('Subject Content', 0),
            _tabItem('Assignments', 1),
          ],
        ),
      ),
    );
  }

  Widget _tabItem(String label, int index) {
    final isSelected = _selectedTab == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedTab = index),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF111111) : Colors.transparent,
            borderRadius: BorderRadius.circular(9),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: isSelected ? Colors.white : const Color(0xFF999999),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ── LESSON LIST ─────────────────────────────────────────
  Widget _buildLessonList() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Text(
                '$_completedLessons of ${kLessons.length} completed',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFFAAAAAA),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: const Color(0xFFE8E8E8)),
                borderRadius: BorderRadius.circular(14),
              ),
              child: ListView.separated(
                itemCount: kLessons.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (context, index) =>
                    _buildLessonItem(kLessons[index]),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLessonItem(Map<String, dynamic> lesson) {
    return ListTile(
      leading: Icon(
        lesson["completed"] ? Icons.check_circle : Icons.play_circle_fill,
        color: lesson["completed"] ? Colors.green : Colors.grey,
      ),
      title: Text(lesson["title"]),
      subtitle: Text(lesson["duration"]),
      trailing: const Icon(Icons.arrow_forward_ios, size: 14),
    );
  }

  // ── ASSIGNMENTS ─────────────────────────────────────────
  Widget _buildAssignments() {
    return const Center(
      child: Text(
        "No assignments yet",
        style: TextStyle(fontSize: 14, color: Colors.grey),
      ),
    );
  }

  // ── BOTTOM NAV ──────────────────────────────────────────
  Widget _buildBottomNav() {
    return Container(
      height: 60,
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: Color(0xFFE5E7EB))),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: const [
          Icon(Icons.home_outlined),
          Icon(Icons.description_outlined),
          Icon(Icons.favorite_border),
          Icon(Icons.person_outline),
        ],
      ),
    );
  }
}
