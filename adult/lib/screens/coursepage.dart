import 'dart:io';
import 'package:adult/Model/content.dart';
import 'package:flutter/material.dart';
import '../service/contentService.dart';
import 'package:provider/provider.dart';
import 'package:adult/service/sync_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:adult/Model/quiz.dart';
import 'package:adult/service/quiz_service.dart';
import 'package:adult/screens/color.dart';
import 'quiz_taking_screen.dart'; // adjust path to wherever you place it
import 'pdf_viewer.dart'; // adjust path to wherever you place it
import 'video_player.dart'; // adjust path to wherever you place it

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
  bool _contentRequested = false; // didChangeDependencies can fire often

  int get subjectId => widget.subjectId;

  @override
  void initState() {
    super.initState();
    debugPrint('>>> CoursePage subjectId: $subjectId');
    _loadQuizzes();
  }

  Future<void> _loadQuizzes() async {
    // Read before the first await — context isn't safe to use after it.
    final db = context.read<SyncService>().db;
    final prefs = await SharedPreferences.getInstance();
    final institutionId = prefs.getInt('institution') ?? 0;
    final programmeId = prefs.getInt('programme_id');
    if (!mounted) return;
    setState(() {
      _quizzesFuture = QuizService(db: db).fetchQuizzes(
        subjectId: subjectId,
        institutionId: institutionId,
        programmeId: programmeId,
      );
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_contentRequested) {
      _contentRequested = true;
      final db = context.read<SyncService>().db;
      _coursePageFuture = contentService(db: db).getContent(subjectId);
    }
  }

  void _toast(String text, {bool isError = false, Duration? duration}) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          duration: duration ?? const Duration(seconds: 3),
          backgroundColor: isError ? EduColors.danger : EduColors.textPrimary,
          shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          content: Text(
            text,
            style: const TextStyle(color: EduColors.onPrimary),
          ),
        ),
      );
  }

  // ── Open a lesson ──
  // 1. use the downloaded file if it exists
  // 2. otherwise download it now (and record the path in the DB)
  // 3. if that fails (offline), return the URL so the caller can tell the user

  Future<String?> _resolveSource(ContentModel lesson) async {
    final local = lesson.localPath;
    if (local != null && await File(local).exists()) return local;

    if (lesson.fileUrl.isEmpty) return null;
    if (!mounted) return null;

    _toast('Downloading...', duration: const Duration(seconds: 30));

    final sync = context.read<SyncService>(); // read before the await
    final path = await sync.ensureLocalFile(lesson.id, lesson.fileUrl);
    return path ?? lesson.fileUrl;
  }

  Future<void> _openLesson(ContentModel lesson) async {
    debugPrint('🔎 Tapped "${lesson.title}" localPath=${lesson.localPath}');
    final source = await _resolveSource(lesson);
    if (!mounted) return;
    ScaffoldMessenger.of(context).hideCurrentSnackBar();

    if (source == null || source.isEmpty) {
      _toast('This file is not available.', isError: true);
      return;
    }

    final isNetwork = source.startsWith('http');
    debugPrint(
        '📂 Opening "${lesson.title}" from ${isNetwork ? 'network' : 'local'}: $source');

    final type = lesson.type.toLowerCase();
    // Decide by the file extension as well as the stored type, because the
    // server's type string may not be exactly "pdf" (e.g. "document").
    final isPdf = type.contains('pdf') || source.toLowerCase().endsWith('.pdf');
    debugPrint('🔎 type="${lesson.type}" isPdf=$isPdf');

    if (isPdf) {
      if (isNetwork) {
        // Download failed, so there is no local file to show.
        _toast(
          'Could not download the file. Check your connection and try again.',
          isError: true,
        );
        return;
      }
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => PdfViewerScreen(path: source, title: lesson.title),
        ),
      );
    } else if (type.contains('video') ||
        RegExp(r'\.(mp4|mov|mkv|webm|3gp|m4v)$')
            .hasMatch(source.toLowerCase())) {
      if (isNetwork) {
        // Download failed, so there is no local file to play.
        _toast(
          'Could not download the video. Check your connection and try again.',
          isError: true,
        );
        return;
      }
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => VideoPlayerScreen(path: source, title: lesson.title),
        ),
      );
    } else {
      _toast('Can\'t open "${lesson.type}" files yet.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: EduColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeaderCard(),
              const SizedBox(height: 20),
              _buildTabBar(),
              const SizedBox(height: 18),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 250),
                child: KeyedSubtree(
                  key: ValueKey(_selectedTab),
                  child:
                  _selectedTab == 0 ? _buildLessonList() : _buildAssignments(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Header card ────────────────────────────────────────────────────────

  Widget _buildHeaderCard() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [EduColors.primary, EduColors.primaryDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: const [
          BoxShadow(
            color: Color(0x403D5CFF),
            blurRadius: 24,
            offset: Offset(0, 12),
          ),
        ],
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
              color: EduColors.onPrimary,
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
                color: EduColors.onPrimaryMuted,
                fontSize: 13,
                height: 1.45,
              ),
            ),
          ],
          const SizedBox(height: 18),
          Row(
            children: [
              FutureBuilder<List<ContentModel>>(
                future: _coursePageFuture,
                builder: (context, snapshot) {
                  final count = snapshot.data?.length ?? 0;
                  return _statChip(
                    icon: Icons.play_circle_outline_rounded,
                    label: '$count Lesson${count == 1 ? '' : 's'}',
                  );
                },
              ),
              const SizedBox(width: 8),
              if (_quizzesFuture != null)
                FutureBuilder<List<Quiz>>(
                  future: _quizzesFuture,
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) return const SizedBox.shrink();
                    final count = snapshot.data!.length;
                    return _statChip(
                      icon: Icons.assignment_outlined,
                      label: '$count Assignment${count == 1 ? '' : 's'}',
                    );
                  },
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _circleIconButton(IconData icon, {required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: const BoxDecoration(
          color: EduColors.onPrimaryFaint,
          shape: BoxShape.circle,
        ),
        child: Icon(icon, size: 17, color: EduColors.onPrimary),
      ),
    );
  }

  Widget _statChip({required IconData icon, required String label}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
      decoration: BoxDecoration(
        color: const Color(0x1AFFFFFF),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: EduColors.onPrimaryFaint),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: EduColors.onPrimary),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              color: EduColors.onPrimary,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  // ── Tabs ───────────────────────────────────────────────────────────────

  Widget _buildTabBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: EduColors.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: EduColors.border),
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
          curve: Curves.easeOut,
          padding: const EdgeInsets.symmetric(vertical: 11),
          decoration: BoxDecoration(
            color: isSelected ? EduColors.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: isSelected
                    ? EduColors.onPrimary
                    : EduColors.textSecondary,
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ── Shared states ──────────────────────────────────────────────────────

  Widget _loadingState() => const Padding(
    padding: EdgeInsets.all(48),
    child: Center(
      child: CircularProgressIndicator(color: EduColors.primary),
    ),
  );

  Widget _messageState({
    required IconData icon,
    required String title,
    required String message,
  }) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(32, 40, 32, 40),
      child: Column(
        children: [
          Container(
            width: 68,
            height: 68,
            decoration: BoxDecoration(
              color: EduColors.primarySoft,
              borderRadius: BorderRadius.circular(22),
            ),
            child: Icon(icon, color: EduColors.primary, size: 32),
          ),
          const SizedBox(height: 16),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: EduColors.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 13,
              height: 1.4,
              color: EduColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  // ── Lesson list ────────────────────────────────────────────────────────

  Widget _buildLessonList() {
    return FutureBuilder<List<ContentModel>>(
      future: _coursePageFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _loadingState();
        }

        if (snapshot.hasError) {
          return _messageState(
            icon: Icons.cloud_off_rounded,
            title: "Couldn't load lessons",
            message: 'Check your connection and try again.\n${snapshot.error}',
          );
        }

        final lessons = snapshot.data ?? [];

        if (lessons.isEmpty) {
          return _messageState(
            icon: Icons.menu_book_rounded,
            title: 'No content yet',
            message: 'Lessons for this subject will appear here.',
          );
        }

        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (int i = 0; i < lessons.length; i++)
                _EntranceFade(
                  index: i,
                  child: _buildLessonRow(
                    lessons[i],
                    number: i + 1,
                    isLast: i == lessons.length - 1,
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildLessonRow(
      ContentModel lesson, {
        required int number,
        required bool isLast,
      }) {
    final fg = _fgFor(lesson.type);
    final bg = _bgFor(lesson.type);

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Timeline rail: numbered marker + connecting line
          SizedBox(
            width: 28,
            child: Column(
              children: [
                Container(
                  width: 26,
                  height: 26,
                  margin: const EdgeInsets.only(top: 18),
                  alignment: Alignment.center,
                  decoration: const BoxDecoration(
                    color: EduColors.primary,
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    '$number',
                    style: const TextStyle(
                      color: EduColors.onPrimary,
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 2,
                      margin: const EdgeInsets.only(top: 4),
                      color: EduColors.primarySoft,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 12),
              // Material owns the fill so the InkWell ripple is visible
              // and clipped to the rounded corners.
              child: Material(
                color: EduColors.surface,
                elevation: 0,
                clipBehavior: Clip.antiAlias,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                  side: const BorderSide(color: EduColors.border),
                ),
                child: InkWell(
                  onTap: () => _openLesson(lesson),
                  splashColor: EduColors.primarySoft,
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Row(
                      children: [
                        Container(
                          width: 46,
                          height: 46,
                          decoration: BoxDecoration(
                            color: bg,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Icon(_iconFor(lesson.type),
                              size: 22, color: fg),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                lesson.title,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 14,
                                  height: 1.3,
                                  color: EduColors.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: bg,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  lesson.type,
                                  style: TextStyle(
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.w700,
                                    color: fg,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          width: 32,
                          height: 32,
                          decoration: const BoxDecoration(
                            color: EduColors.primarySoft,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.chevron_right_rounded,
                            color: EduColors.primary,
                            size: 20,
                          ),
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
        return Icons.play_circle_fill_rounded;
      case 'pdf':
        return Icons.picture_as_pdf_rounded;
      case 'quiz':
        return Icons.quiz_rounded;
      default:
        return Icons.article_rounded;
    }
  }

  Color _fgFor(String type) {
    switch (type.toLowerCase()) {
      case 'video':
        return EduColors.primary;
      case 'pdf':
        return EduColors.accent;
      case 'quiz':
        return EduColors.success;
      default:
        return EduColors.primary;
    }
  }

  Color _bgFor(String type) {
    switch (type.toLowerCase()) {
      case 'video':
        return EduColors.primarySoft;
      case 'pdf':
        return EduColors.accentSoft;
      case 'quiz':
        return EduColors.successSoft;
      default:
        return EduColors.primarySoft;
    }
  }

  // ── Assignments ────────────────────────────────────────────────────────

  Widget _buildAssignments() {
    if (_quizzesFuture == null) return _loadingState();

    return FutureBuilder<List<Quiz>>(
      future: _quizzesFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _loadingState();
        }
        if (snapshot.hasError) {
          return _messageState(
            icon: Icons.cloud_off_rounded,
            title: "Couldn't load assignments",
            message: 'Check your connection and try again.\n${snapshot.error}',
          );
        }
        final quizzes = snapshot.data ?? [];
        if (quizzes.isEmpty) {
          return _messageState(
            icon: Icons.assignment_turned_in_outlined,
            title: 'No assignments yet',
            message: 'Quizzes and assignments will show up here.',
          );
        }
        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
          child: Column(
            children: [
              for (int i = 0; i < quizzes.length; i++)
                _EntranceFade(
                  index: i,
                  child: _buildQuizCard(quizzes[i]),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _metaChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: EduColors.background,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: EduColors.textSecondary),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w700,
              color: EduColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuizCard(Quiz quiz) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      // Material owns the fill + border so the ink splash isn't hidden.
      child: Material(
        color: EduColors.surface,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: EduColors.border),
        ),
        child: InkWell(
          splashColor: EduColors.primarySoft,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => QuizTakingScreen(quiz: quiz),
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: EduColors.successSoft,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(Icons.quiz_rounded,
                      size: 22, color: EduColors.success),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        quiz.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                          height: 1.3,
                          color: EduColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: [
                          _metaChip(
                            Icons.help_outline_rounded,
                            '${quiz.questionCount} question${quiz.questionCount == 1 ? '' : 's'}',
                          ),
                          _metaChip(
                            Icons.stars_rounded,
                            '${quiz.totalPoints} points',
                          ),
                          if (quiz.timeLimitMinutes != null)
                            _metaChip(
                              Icons.timer_outlined,
                              '${quiz.timeLimitMinutes} min',
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  width: 32,
                  height: 32,
                  decoration: const BoxDecoration(
                    color: EduColors.primary,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.arrow_forward_rounded,
                    color: EduColors.onPrimary,
                    size: 16,
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

/// Fades + slides each row in with a small stagger.
class _EntranceFade extends StatelessWidget {
  final int index;
  final Widget child;

  const _EntranceFade({required this.index, required this.child});

  @override
  Widget build(BuildContext context) {
    final delay = (index * 50).clamp(0, 350);
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 350 + delay),
      curve: Curves.easeOutCubic,
      builder: (context, v, child) => Opacity(
        opacity: v,
        child: Transform.translate(
          offset: Offset(0, (1 - v) * 16),
          child: child,
        ),
      ),
      child: child,
    );
  }
}