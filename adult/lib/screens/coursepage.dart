import 'package:adult/Model/content.dart';
import 'package:flutter/material.dart';
import '../service/contentService.dart';
import 'package:provider/provider.dart';
import 'package:adult/service/sync_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:adult/Model/quiz.dart';
import 'package:adult/service/quiz_service.dart';
import 'quiz_taking_screen.dart'; // adjust path to wherever you place it

typedef Content = ContentModel;

class CoursePage extends StatefulWidget {
  final int subjectId;

  const CoursePage({super.key, required this.subjectId});

  @override
  State<CoursePage> createState() => _CoursePageState();
}

class _CoursePageState extends State<CoursePage> {
  late Future<List<ContentModel>> _coursePageFuture;
  Future<List<Quiz>>? _quizzesFuture;
  int _selectedTab = 0;

  int get subjectId => widget.subjectId;

  @override
  void initState() {
    super.initState();
    print('>>> CoursePage subjectId: $subjectId');
    _loadQuizzes();
  }

  Future<void> _loadQuizzes() async {
    final prefs = await SharedPreferences.getInstance();
    final institutionId = prefs.getInt('institution') ?? 0;
    final programmeId = prefs.getInt('programme_id');
    setState(() {
      _quizzesFuture = QuizService().fetchQuizzes(
        subjectId: subjectId,
        institutionId: institutionId,
        programmeId: programmeId,
      );
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final db = context.read<SyncService>().db;
    _coursePageFuture = contentService(db: db).getContent(subjectId);
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
    );
  }

  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _iconButton(
            Icons.arrow_back_ios_new_rounded,
            onTap: () {
              Navigator.pop(context);
            },
          ),
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
    return const Padding(
      padding: EdgeInsets.fromLTRB(16, 14, 16, 0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
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
    );
  }

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
                color: isSelected ? Colors.white : const Color(0xFF111111),
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
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Text(
              'Error: ${snapshot.error}',
              style: const TextStyle(color: Colors.red),
            ),
          );
        }

        final lessons = snapshot.data ?? [];

        if (lessons.isEmpty) {
          return const Center(child: Text('No Content available.'));
        }

        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: lessons.length,

          // 1. SPACING between items — change SizedBox height
          separatorBuilder: (_, __) => const SizedBox(height: 8),

          itemBuilder: (context, index) {
            return Container(
              // 2. BORDER & SHAPE — add decoration here
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: Colors.black, width: 1),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.10),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              // 3. INNER PADDING — space between border and content
              child: _buildLessonItem(lessons[index]),
            );
          },
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
      leading: Icon(typeIcon),
      title: Text(lesson.title),
      subtitle: Text(lesson.type),
    );
  }

  Widget _buildAssignments() {
    if (_quizzesFuture == null) {
      return const Center(child: CircularProgressIndicator());
    }
    return FutureBuilder<List<Quiz>>(
      future: _quizzesFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(
            child: Text(
              'Error: ${snapshot.error}',
              style: const TextStyle(color: Colors.red),
            ),
          );
        }
        final quizzes = snapshot.data ?? [];
        if (quizzes.isEmpty) {
          return const Center(child: Text('No assignments yet'));
        }
        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: quizzes.length,
          separatorBuilder: (_, __) => const SizedBox(height: 8),
          itemBuilder: (context, index) {
            final quiz = quizzes[index];
            return Container(
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: Colors.black, width: 1),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.10),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: ListTile(
                leading: const Icon(Icons.quiz),
                title: Text(quiz.title),
                subtitle: Text(
                  '${quiz.questionCount} question${quiz.questionCount == 1 ? '' : 's'} · ${quiz.totalPoints} points'
                  '${quiz.timeLimitMinutes != null ? ' · ${quiz.timeLimitMinutes} min' : ''}',
                ),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => QuizTakingScreen(quiz: quiz),
                    ),
                  );
                },
              ),
            );
          },
        );
      },
    );
  }
}
