import 'package:adult/Model/content.dart';
import 'package:flutter/material.dart';
import '../service/contentService.dart';

typedef Content = ContentModel;

class CoursePage extends StatefulWidget {
  const CoursePage({super.key});

  @override
  State<CoursePage> createState() => _CoursePageState();
}

class _CoursePageState extends State<CoursePage> {
  late Future<List<ContentModel>> _coursePageFuture;
  int _selectedTab = 0;

  @override
  void initState() {
    super.initState();
    _coursePageFuture = contentService().getContent(1);
  }

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

  Widget _buildCourseInfo() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
      child: Column(
        children: [
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
              CircleAvatar(
                radius: 16,
                backgroundColor: Colors.white,
                child: Icon(Icons.person, size: 18),
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

  Widget _buildLessonList() {
    return FutureBuilder<List<ContentModel>>(
      future: _coursePageFuture,
      builder: (context, snapshot) {
        // 1. Loading state
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        // 2. Error state
        if (snapshot.hasError) {
          return Center(
            child: Text(
              'Error: ${snapshot.error}',
              style: const TextStyle(color: Colors.red),
            ),
          );
        }

        // 3. Empty state
        final lessons = snapshot.data ?? [];
        if (lessons.isEmpty) {
          return const Center(child: Text('No lessons available.'));
        }

        // 4. Data state
        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Text(
                    // Since ContentModel has no "completed" field,
                    // we show total count. Add a completed field to
                    // your model/API later to track progress.
                    '${lessons.length} lessons available',
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
                    itemCount: lessons.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, index) =>
                        _buildLessonItem(lessons[index]),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildLessonItem(ContentModel lesson) {
    IconData typeIcon;
    switch (lesson.type.toLowerCase()) {
      case 'video':
        typeIcon = Icons.play_circle_fill;
        break;
      case 'pdf':
        typeIcon = Icons.picture_as_pdf;
        break;
      case 'quiz':
        typeIcon = Icons.quiz;
        break;
      default:
        typeIcon = Icons.article;
    }

    return ListTile(
      leading: Icon(typeIcon, color: const Color(0xFF111111)),
      title: Text(
        lesson.title,
        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
      ),
      subtitle: Text(
        lesson.type.toUpperCase(),
        style: const TextStyle(fontSize: 11, color: Color(0xFFAAAAAA)),
      ),
      trailing: const Icon(Icons.arrow_forward_ios, size: 14),
      onTap: () {
        // TODO: Navigate to lesson detail, passing lesson.fileUrl
        // Navigator.push(context, MaterialPageRoute(
        //   builder: (_) => LessonDetailPage(url: lesson.fileUrl),
        // ));
      },
    );
  }

  Widget _buildAssignments() {
    return const Center(
      child: Text(
        "No assignments yet",
        style: TextStyle(fontSize: 14, color: Colors.grey),
      ),
    );
  }

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
