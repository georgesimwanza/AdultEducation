import 'dart:io'; // ← added (for File)
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

  /// TODO: wire these in from wherever CoursePage is navigated to — the
  /// screen that lists subjects/courses already has this data (it's what
  /// renders the course tile you tapped to get here). Falling back to
  /// placeholders for now so the page still renders correctly.
  final String? subjectTitle;
  final String? subjectDescription;

  const CoursePage({
    super.key,
    required this.subjectId,
    this.subjectTitle,
    this.subjectDescription,
  });

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

  // ── Open a lesson: prefer the downloaded local file, fall back to the
  // network URL if it hasn't been downloaded (or was deleted) ──
  Future<String?> _resolveSource(ContentModel lesson) async {
    final local = lesson.localPath;
    if (local != null && await File(local).exists()) return local;
    return lesson.fileUrl; // fall back to network
  }

  Future<void> _openLesson(ContentModel lesson) async {
    final source = await _resolveSource(lesson);
    if (!mounted) return;

    if (source == null || source.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('This file is not available.')),
      );
      return;
    }

    final isNetwork = source.startsWith('http');
    print('📂 Opening "${lesson.title}" from ${isNetwork ? 'network' : 'local'}: $source');

    switch (lesson.type.toLowerCase()) {
      case 'pdf':
      // TODO: local   -> PDFView(filePath: source)
      //       network -> your existing network PDF viewer
        break;
      case 'video':
      // TODO: isNetwork loading
      //   ? VideoPlayerController.networkUrl(Uri.parse(source))
      //   : VideoPlayerController.file(File(source))
        break;
      default:
      // TODO: images etc.
      //   isNetwork ? Image.network(source) : Image.file(File(source))
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F7),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeaderCard(),
                    const SizedBox(height: 20),
                    _buildTabBar(),
                    const SizedBox(height: 16),
                    _selectedTab == 0 ? _buildLessonList() : _buildAssignments(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Header card — dark rounded card with back/settings, title,
  // description, and stat chips, mirroring the mockup's top section ──
  Widget _buildHeaderCard() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 22),
      decoration: BoxDecoration(
        color: const Color(0xFF111111),
        borderRadius: BorderRadius.circular(28),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _circleIconButton(
                Icons.arrow_back_ios_new_rounded,
                onTap: () => Navigator.pop(context),
              ),
              _circleIconButton(Icons.more_horiz_rounded, onTap: () {}),
            ],
          ),
          const SizedBox(height: 20),
          Text(
            widget.subjectTitle ?? 'Subject $subjectId',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.w800,
              height: 1.15,
            ),
          ),
          if ((widget.subjectDescription ?? '').isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              widget.subjectDescription!,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Color(0xFFB3B3B3),
                fontSize: 13,
                height: 1.4,
              ),
            ),
          ],
          const SizedBox(height: 18),
          FutureBuilder<List<ContentModel>>(
            future: _coursePageFuture,
            builder: (context, snapshot) {
              final count = snapshot.data?.length ?? 0;
              return Row(
                children: [
                  _statChip(
                    icon: Icons.play_circle_outline,
                    label: '$count Lesson${count == 1 ? '' : 's'}',
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _circleIconButton(IconData icon, {required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: const Color(0xFF262626),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, size: 16, color: Colors.white),
      ),
    );
  }

  Widget _statChip({required IconData icon, required String label}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFF2E2E2E)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: Colors.white),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
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
          color: const Color(0xFFEFEFEF),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            _tabItem('Lesson Library', 0),
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
            borderRadius: BorderRadius.circular(10),
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

  // ── Lesson list — timeline-style rows, connector line on the left,
  // circular markers, matching the mockup's left rail ──
  Widget _buildLessonList() {
    return FutureBuilder<List<ContentModel>>(
      future: _coursePageFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Padding(
            padding: EdgeInsets.all(32),
            child: Center(child: CircularProgressIndicator(color: Colors.black)),
          );
        }

        if (snapshot.hasError) {
          return Padding(
            padding: const EdgeInsets.all(32),
            child: Center(
              child: Text(
                'Error: ${snapshot.error}',
                style: const TextStyle(color: Colors.red),
              ),
            ),
          );
        }

        final lessons = snapshot.data ?? [];

        if (lessons.isEmpty) {
          return const Padding(
            padding: EdgeInsets.all(32),
            child: Center(child: Text('No Content available.')),
          );
        }

        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Lesson Library',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF111111),
                      ),
                    ),
                    Text(
                      'See More',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 4),
              for (int i = 0; i < lessons.length; i++)
                _buildLessonRow(lessons[i], isLast: i == lessons.length - 1),
            ],
          ),
        );
      },
    );
  }

  Widget _buildLessonRow(ContentModel lesson, {required bool isLast}) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Timeline rail: dot + connecting line
          Column(
            children: [
              Container(
                width: 10,
                height: 10,
                margin: const EdgeInsets.only(top: 22),
                decoration: const BoxDecoration(
                  color: Color(0xFF111111),
                  shape: BoxShape.circle,
                ),
              ),
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 2,
                    color: const Color(0xFFDDDDDD),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 12),
              // Material (not Container) owns the white fill + border so the
              // InkWell ripple is visible and clipped to the rounded corners.
              child: Material(
                color: Colors.white,
                clipBehavior: Clip.antiAlias,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: const BorderSide(color: Color(0xFFE4E4E4)),
                ),
                child: InkWell(
                  onTap: () => _openLesson(lesson),
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: const Color(0xFF111111),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            _iconFor(lesson.type),
                            size: 18,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                lesson.title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 14,
                                  color: Color(0xFF111111),
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                lesson.type,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Icon(
                          Icons.chevron_right_rounded,
                          color: Colors.grey.shade400,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  IconData _iconFor(String type) {
    switch (type.toLowerCase()) {
      case 'video':
        return Icons.play_circle_fill;
      case 'pdf':
        return Icons.picture_as_pdf;
      case 'quiz':
        return Icons.quiz;
      default:
        return Icons.article;
    }
  }

  Widget _buildAssignments() {
    if (_quizzesFuture == null) {
      return const Padding(
        padding: EdgeInsets.all(32),
        child: Center(child: CircularProgressIndicator(color: Colors.black)),
      );
    }
    return FutureBuilder<List<Quiz>>(
      future: _quizzesFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Padding(
            padding: EdgeInsets.all(32),
            child: Center(child: CircularProgressIndicator(color: Colors.black)),
          );
        }
        if (snapshot.hasError) {
          return Padding(
            padding: const EdgeInsets.all(32),
            child: Center(
              child: Text(
                'Error: ${snapshot.error}',
                style: const TextStyle(color: Colors.red),
              ),
            ),
          );
        }
        final quizzes = snapshot.data ?? [];
        if (quizzes.isEmpty) {
          return const Padding(
            padding: EdgeInsets.all(32),
            child: Center(child: Text('No assignments yet')),
          );
        }
        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
          child: Column(
            children: [
              for (final quiz in quizzes)
                Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(color: const Color(0xFFE4E4E4)),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: ListTile(
                    leading: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: const Color(0xFF111111),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.quiz, size: 18, color: Colors.white),
                    ),
                    title: Text(
                      quiz.title,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    subtitle: Text(
                      '${quiz.questionCount} question${quiz.questionCount == 1 ? '' : 's'} · ${quiz.totalPoints} points'
                          '${quiz.timeLimitMinutes != null ? ' · ${quiz.timeLimitMinutes} min' : ''}',
                      style: TextStyle(color: Colors.grey.shade600),
                    ),
                    trailing: Icon(
                      Icons.chevron_right_rounded,
                      color: Colors.grey.shade400,
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
                ),
            ],
          ),
        );
      },
    );
  }
}