import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../Model/subject_model.dart';
import '../service/subject_service.dart';
import 'package:adult/Controller/auth_controller.dart';
import 'package:adult/service/sync_service.dart';
import 'package:adult/screens/color.dart';

class SubjectPage extends StatefulWidget {
  const SubjectPage({super.key});

  @override
  State<SubjectPage> createState() => _SubjectPageState();
}

class _SubjectPageState extends State<SubjectPage> {
  final TextEditingController _searchController = TextEditingController();
  late subjectService _service;
  String _searchQuery = '';
  List<subjectModel> _subjects = [];
  bool _isLoading = true;
  String? _errorMessage;
  bool _loaded = false; // prevent duplicate calls

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_loaded) {
      _loaded = true;
      _service = subjectService(db: context.read<SyncService>().db);
      _loadSubjects();
    }
  }

  Future<void> _loadSubjects() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
      final controller = Provider.of<AuthController>(context, listen: false);
      final programmeId = controller.programmeId;

      debugPrint('>>> SubjectPage programmeId: $programmeId');

      if (programmeId == null) {
        if (!mounted) return;
        setState(() {
          _errorMessage = 'No programme selected. Please log in again.';
          _isLoading = false;
        });
        return;
      }

      final data = await _service.getSubjectsByProgramme(programmeId);
      if (!mounted) return;
      setState(() {
        _subjects = data;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('>>> SubjectPage error: $e');
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Failed to load subjects. Please try again.';
        _isLoading = false;
      });
    }
  }

  List<subjectModel> get _filtered => _searchQuery.isEmpty
      ? _subjects
      : _subjects
      .where(
        (s) =>
    s.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
        s.code.toLowerCase().contains(_searchQuery.toLowerCase()),
  )
      .toList();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: EduColors.background,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            Expanded(child: _buildBody()),
          ],
        ),
      ),
    );
  }

  // ── Header ─────────────────────────────────────────────────────────────

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              GestureDetector(
                onTap: () => Navigator.maybePop(context),
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: EduColors.surface,
                    shape: BoxShape.circle,
                    border: Border.all(color: EduColors.border),
                  ),
                  child: const Icon(Icons.arrow_back_rounded,
                      color: EduColors.textPrimary, size: 20),
                ),
              ),
              const SizedBox(width: 14),
              // Matches the "Browse Courses" card icon on the dashboard
              // (same tag) so it flies into this badge on navigation.
              Hero(
                tag: 'browse-courses-icon',
                child: Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: EduColors.primarySoft,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(
                    Icons.menu_book_rounded,
                    color: EduColors.primary,
                    size: 24,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Subjects',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        color: EduColors.textPrimary,
                        letterSpacing: -0.4,
                      ),
                    ),
                    Text(
                      _isLoading
                          ? 'Loading…'
                          : '${_subjects.length} ${_subjects.length == 1 ? 'course' : 'courses'} available',
                      style: const TextStyle(
                        fontSize: 12,
                        color: EduColors.textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          _buildSearchBar(),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      height: 54,
      decoration: BoxDecoration(
        color: EduColors.surface,
        borderRadius: BorderRadius.circular(27),
        border: Border.all(color: EduColors.border),
      ),
      child: TextField(
        controller: _searchController,
        onChanged: (v) => setState(() => _searchQuery = v),
        cursorColor: EduColors.primary,
        style: const TextStyle(color: EduColors.textPrimary, fontSize: 14),
        decoration: InputDecoration(
          hintText: 'What do you want to learn?',
          hintStyle: const TextStyle(
            color: EduColors.textSecondary,
            fontSize: 14,
          ),
          prefixIcon: const Icon(
            Icons.search_rounded,
            color: EduColors.textSecondary,
          ),
          suffixIcon: _searchQuery.isEmpty
              ? null
              : IconButton(
            icon: const Icon(Icons.close_rounded,
                color: EduColors.textSecondary, size: 20),
            onPressed: () {
              _searchController.clear();
              setState(() => _searchQuery = '');
            },
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 16),
        ),
      ),
    );
  }

  // ── Body ───────────────────────────────────────────────────────────────

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: EduColors.primary),
      );
    }

    if (_errorMessage != null) {
      return _buildMessageState(
        icon: Icons.cloud_off_rounded,
        title: 'Something went wrong',
        message: _errorMessage!,
        showRetry: true,
      );
    }

    if (_subjects.isEmpty) {
      return _buildMessageState(
        icon: Icons.menu_book_rounded,
        title: 'No subjects yet',
        message: 'Courses for your programme will appear here.',
      );
    }

    if (_filtered.isEmpty) {
      return _buildMessageState(
        icon: Icons.search_off_rounded,
        title: 'No courses found',
        message: 'Try a different name or course code.',
      );
    }

    return RefreshIndicator(
      color: EduColors.primary,
      onRefresh: _loadSubjects,
      child: GridView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 14,
          crossAxisSpacing: 14,
          childAspectRatio: 0.85,
        ),
        itemCount: _filtered.length,
        itemBuilder: (context, index) => _EntranceFade(
          index: index,
          child: _SubjectCard(subject: _filtered[index], colorIndex: index),
        ),
      ),
    );
  }

  /// Error / empty states live in a ListView so pull-to-refresh still works.
  Widget _buildMessageState({
    required IconData icon,
    required String title,
    required String message,
    bool showRetry = false,
  }) {
    return RefreshIndicator(
      color: EduColors.primary,
      onRefresh: _loadSubjects,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 32),
        children: [
          const SizedBox(height: 70),
          Center(
            child: Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: EduColors.primarySoft,
                borderRadius: BorderRadius.circular(22),
              ),
              child: Icon(icon, color: EduColors.primary, size: 34),
            ),
          ),
          const SizedBox(height: 18),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 17,
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
          if (showRetry) ...[
            const SizedBox(height: 18),
            Center(
              child: ElevatedButton.icon(
                onPressed: _loadSubjects,
                icon: const Icon(Icons.refresh_rounded, size: 18),
                label: const Text('Try again'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: EduColors.primary,
                  foregroundColor: EduColors.onPrimary,
                  elevation: 0,
                  padding:
                  const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ── Subject Card ─────────────────────────────────────────────────────────

class _SubjectCard extends StatefulWidget {
  final subjectModel subject;
  final int colorIndex;
  const _SubjectCard({required this.subject, required this.colorIndex});

  @override
  State<_SubjectCard> createState() => _SubjectCardState();
}

class _SubjectCardState extends State<_SubjectCard> {
  bool _pressed = false;

  // Cycles through the palette so the grid isn't one flat colour.
  static const List<Color> _fgColors = [
    EduColors.primary,
    EduColors.accent,
    EduColors.success,
  ];
  static const List<Color> _bgColors = [
    EduColors.primarySoft,
    EduColors.accentSoft,
    EduColors.successSoft,
  ];

  void _enter() {
    Navigator.pushNamed(
      context,
      '/coursepage',
      arguments: widget.subject.id, // ← pass subject id
    );
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Entering ${widget.subject.name}...'),
        duration: const Duration(seconds: 1),
        behavior: SnackBarBehavior.floating,
        backgroundColor: EduColors.textPrimary,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.subject;
    final fg = _fgColors[widget.colorIndex % _fgColors.length];
    final bg = _bgColors[widget.colorIndex % _bgColors.length];

    return AnimatedScale(
      scale: _pressed ? 0.96 : 1.0,
      duration: const Duration(milliseconds: 120),
      child: GestureDetector(
        onTapDown: (_) => setState(() => _pressed = true),
        onTapUp: (_) => setState(() => _pressed = false),
        onTapCancel: () => setState(() => _pressed = false),
        onTap: _enter,
        child: Container(
          decoration: BoxDecoration(
            color: EduColors.surface,
            borderRadius: BorderRadius.circular(22),
            boxShadow: EduColors.cardShadow,
          ),
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: bg,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(Icons.menu_book_rounded, color: fg, size: 24),
              ),
              const Spacer(),
              Text(
                s.name,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: EduColors.textPrimary,
                  height: 1.25,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Flexible(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: EduColors.background,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        s.code,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 10.5,
                          color: EduColors.textSecondary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                  const Spacer(),
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
            ],
          ),
        ),
      ),
    );
  }
}

/// Fades + slides each card in with a small stagger.
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