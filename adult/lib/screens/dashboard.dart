import 'package:provider/provider.dart';
import 'package:adult/Controller/auth_controller.dart';
import 'package:adult/service/dashboard_service.dart';
import 'package:flutter/material.dart';
import './subject.dart';
import 'schedule_screen.dart';
import 'package:adult/service/sync_service.dart';
import 'package:adult/screens/color.dart';

class Dashboard extends StatefulWidget {
  const Dashboard({super.key});

  @override
  State<Dashboard> createState() => DashboardState();
}

class DashboardState extends State<Dashboard>
    with SingleTickerProviderStateMixin {
  String _programmeTitle = 'Loading...';
  bool _titleFetched = false;
  bool _isLoadingTitle = true;
  int _selectedFilter = 0;

  static const List<String> _filters = ['All', 'Courses', 'Schedule'];

  int? _modulesCompleted;
  int? _modulesTotal; // null = still loading

  late final AnimationController _entranceController;

  @override
  void initState() {
    super.initState();
    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    )..forward();
  }

  @override
  void dispose() {
    _entranceController.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_titleFetched) {
      _titleFetched = true;
      _fetchTitle();
      _fetchProgress();
    }
  }

  Future<void> _fetchProgress() async {
    try {
      final programmeId = context.read<AuthController>().programmeId;
      final db = context.read<SyncService>().db;
      if (programmeId == null || db == null) return;

      // ⚠️ adapt table/column names to your schema
      final rows = await db.rawQuery(
        'SELECT COUNT(*) AS total, COALESCE(SUM(completed), 0) AS done '
            'FROM modules WHERE programme_id = ?',
        [programmeId],
      );
      if (!mounted) return;
      setState(() {
        _modulesTotal = (rows.first['total'] as num?)?.toInt() ?? 0;
        _modulesCompleted = (rows.first['done'] as num?)?.toInt() ?? 0;
      });
    } catch (_) {
      // leave as loading/unknown
    }
  }

  Future<void> _fetchTitle() async {
    try {
      final controller = Provider.of<AuthController>(context, listen: false);
      final programmeId = controller.programmeId;
      if (programmeId == null) {
        if (!mounted) return;
        setState(() {
          _programmeTitle = 'No programme selected';
          _isLoadingTitle = false;
        });
        return;
      }

      // Try local storage first
      final db = context.read<SyncService>().db;
      if (db != null) {
        final results = await db.query(
          'programmes',
          where: 'id = ?',
          whereArgs: [programmeId],
        );
        if (results.isNotEmpty) {
          if (!mounted) return;
          setState(() {
            _programmeTitle = results.first['name'] as String;
            _isLoadingTitle = false;
          });
          return;
        }
      }

      // Fall back to server
      final title = await DashboardService().getProgramTitle(programmeId);
      if (!mounted) return;
      setState(() {
        _programmeTitle = title;
        _isLoadingTitle = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _programmeTitle = 'Failed to load';
        _isLoadingTitle = false;
      });
    }
  }

  static const List<BoxShadow> _cardShadow = [
    BoxShadow(
      color: Color(0x143D5CFF),
      blurRadius: 20,
      offset: Offset(0, 8),
    ),
  ];

  final List<_NotifData> _notifications = [
    _NotifData(
      icon: Icons.check_circle_rounded,
      iconColor: EduColors.success,
      tint: const Color(0xFFE3F6EC),
      title: 'Assignment Graded',
      subtitle: 'Social Media Campaign – Score: 95/100',
      time: '2 hours ago',
    ),
    _NotifData(
      icon: Icons.alarm_rounded,
      iconColor: EduColors.accent,
      tint: EduColors.accentSoft,
      title: 'Upcoming Deadline',
      subtitle: 'Module 4 quiz due in 3 days',
      time: '5 hours ago',
    ),
    _NotifData(
      icon: Icons.play_circle_rounded,
      iconColor: EduColors.primary,
      tint: EduColors.primarySoft,
      title: 'New Content Available',
      subtitle: 'Video lectures for Module 5 uploaded',
      time: '1 day ago',
    ),
  ];

  String _timeGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }

  Widget _fadeSlideIn({
    required Widget child,
    required double start,
    double end = 1.0,
  }) {
    final animation = CurvedAnimation(
      parent: _entranceController,
      curve: Interval(start, end, curve: Curves.easeOutCubic),
    );
    return FadeTransition(
      opacity: animation,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.08),
          end: Offset.zero,
        ).animate(animation),
        child: child,
      ),
    );
  }

  Route _fadeRoute(Widget page) {
    return PageRouteBuilder(
      transitionDuration: const Duration(milliseconds: 280),
      pageBuilder: (_, __, ___) => page,
      transitionsBuilder: (_, animation, __, child) {
        final curved = CurvedAnimation(parent: animation, curve: Curves.easeOut);
        return FadeTransition(
          opacity: curved,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, 0.03),
              end: Offset.zero,
            ).animate(curved),
            child: child,
          ),
        );
      },
    );
  }

  void _goToSubjects() {
    Navigator.push(
      context,
      _fadeRoute(
        ChangeNotifierProvider.value(
          value: context.read<AuthController>(),
          child: SubjectPage(),
        ),
      ),
    );
  }

  void _goToSchedule() {
    Navigator.push(
      context,
      _fadeRoute(
        ChangeNotifierProvider.value(
          value: context.read<AuthController>(),
          child: ScheduleScreen(),
        ),
      ),
    );
  }

  void _openNotifications() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: EduColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 12,
            bottom: MediaQuery.of(context).viewInsets.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: EduColors.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Notifications',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: EduColors.textPrimary,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded,
                        color: EduColors.textSecondary),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              _AnimatedNotifList(
                notifications: _notifications,
                tileBuilder: _buildNotifTile,
              ),
            ],
          ),
        );
      },
    );
  }

  bool get _showCourses => _selectedFilter == 0 || _selectedFilter == 1;
  bool get _showSchedule => _selectedFilter == 0 || _selectedFilter == 2;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: EduColors.background,
      body: SafeArea(
        child: RefreshIndicator(
          color: EduColors.primary,
          onRefresh: () async {
            setState(() => _isLoadingTitle = true);
            await Future.wait([_fetchTitle(), _fetchProgress()]);
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _fadeSlideIn(start: 0.0, end: 0.5, child: _buildHeader()),
                const SizedBox(height: 22),
                _fadeSlideIn(
                  start: 0.08,
                  end: 0.55,
                  child: _buildSearchBar(),
                ),
                const SizedBox(height: 20),
                _fadeSlideIn(
                  start: 0.12,
                  end: 0.6,
                  child: _buildFilterChips(),
                ),
                const SizedBox(height: 20),
                _fadeSlideIn(
                  start: 0.18,
                  end: 0.75,
                  child: _buildCurrentProgramCard(),
                ),
                const SizedBox(height: 26),
                _fadeSlideIn(
                  start: 0.28,
                  end: 0.85,
                  child: _buildSectionTitle('Quick access'),
                ),
                const SizedBox(height: 12),
                AnimatedSize(
                  duration: const Duration(milliseconds: 250),
                  curve: Curves.easeOut,
                  alignment: Alignment.topCenter,
                  child: Column(
                    children: [
                      if (_showCourses)
                        _fadeSlideIn(
                          start: 0.32,
                          end: 0.9,
                          child: _TapScale(
                            onTap: _goToSubjects,
                            child: _buildEntryCard(
                              icon: Icons.menu_book_rounded,
                              iconColor: EduColors.primary,
                              tint: EduColors.primarySoft,
                              title: 'Browse Courses',
                              subtitle: 'Explore new programs',
                              heroTag: 'browse-courses-icon',
                            ),
                          ),
                        ),
                      if (_showCourses && _showSchedule)
                        const SizedBox(height: 12),
                      if (_showSchedule)
                        _fadeSlideIn(
                          start: 0.38,
                          end: 0.95,
                          child: _TapScale(
                            onTap: _goToSchedule,
                            child: _buildEntryCard(
                              icon: Icons.calendar_month_rounded,
                              iconColor: EduColors.accent,
                              tint: EduColors.accentSoft,
                              title: 'Schedule',
                              subtitle: 'View your timetable',
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 26),
                _fadeSlideIn(
                  start: 0.45,
                  end: 1.0,
                  child: _buildSectionTitle(
                    'Recent activity',
                    actionLabel: 'See all',
                    onAction: _openNotifications,
                  ),
                ),
                const SizedBox(height: 12),
                _fadeSlideIn(
                  start: 0.5,
                  end: 1.0,
                  child: Column(
                    children: _notifications.take(2).map(_buildNotifTile).toList(),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ───────────────────────── Header ─────────────────────────

  Widget _buildHeader() {
    return Row(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [EduColors.primary, EduColors.primaryDark],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.person_rounded,
              color: EduColors.onPrimary, size: 24),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${_timeGreeting()} 👋',
                style: const TextStyle(
                  color: EduColors.textSecondary,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              const Text(
                'Learn at your own pace',
                style: TextStyle(
                  color: EduColors.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
        GestureDetector(
          onTap: _openNotifications,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: EduColors.surface,
                  shape: BoxShape.circle,
                  border: Border.all(color: EduColors.border),
                ),
                child: const Icon(
                  Icons.notifications_none_rounded,
                  color: EduColors.textPrimary,
                  size: 22,
                ),
              ),
              if (_notifications.isNotEmpty)
                const Positioned(top: 0, right: 0, child: _PulseDot()),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSearchBar() {
    return _TapScale(
      onTap: _goToSubjects,
      child: Container(
        height: 52,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: EduColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: EduColors.border),
        ),
        child: Row(
          children: [
            const Icon(Icons.search_rounded,
                color: EduColors.textSecondary, size: 22),
            const SizedBox(width: 10),
            const Expanded(
              child: Text(
                'Search courses, modules…',
                style: TextStyle(color: EduColors.textSecondary, fontSize: 14),
              ),
            ),
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: EduColors.primarySoft,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.tune_rounded,
                  color: EduColors.primary, size: 18),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChips() {
    return SizedBox(
      height: 38,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _filters.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final isSelected = _selectedFilter == index;
          return GestureDetector(
            onTap: () => setState(() => _selectedFilter = index),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOut,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: isSelected ? EduColors.primary : EduColors.surface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isSelected ? EduColors.primary : EduColors.border,
                ),
              ),
              child: AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 200),
                style: TextStyle(
                  color: isSelected
                      ? EduColors.onPrimary
                      : EduColors.textSecondary,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
                child: Text(_filters[index]),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSectionTitle(String title,
      {String? actionLabel, VoidCallback? onAction}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: EduColors.textPrimary,
            fontSize: 17,
            fontWeight: FontWeight.w800,
          ),
        ),
        if (actionLabel != null)
          GestureDetector(
            onTap: onAction,
            child: Text(
              actionLabel,
              style: const TextStyle(
                color: EduColors.primary,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
      ],
    );
  }

  // ───────────────────────── Hero program card ─────────────────────────

  Widget _buildCurrentProgramCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [EduColors.primary, EduColors.primaryDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: EduColors.onPrimaryFaint,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  'Current Program',
                  style: TextStyle(
                    color: EduColors.onPrimary,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const Spacer(),
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: EduColors.onPrimaryFaint,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.school_rounded,
                    color: EduColors.onPrimary, size: 22),
              ),
            ],
          ),
          const SizedBox(height: 14),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: _isLoadingTitle
                ? const _ShimmerLine(
                key: ValueKey('shimmer'), width: 180, height: 22)
                : Text(
              _programmeTitle,
              key: const ValueKey('title'),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: EduColors.onPrimary,
                fontSize: 20,
                fontWeight: FontWeight.w800,
                height: 1.25,
              ),
            ),
          ),
          const SizedBox(height: 20),
          _buildProgressSection(),
          const SizedBox(height: 18),
          Row(
            children: [
              _buildStatChip(Icons.access_time_rounded, '6 mo', 'Duration'),
              const SizedBox(width: 10),
              _buildStatChip(Icons.hourglass_bottom_rounded, '2 mo', 'Time left'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProgressSection() {
    final total = _modulesTotal;
    final done = _modulesCompleted ?? 0;

    if (total == null) {
      return const _ShimmerLine(
          key: ValueKey('p-shimmer'), width: 220, height: 40);
    }
    if (total == 0) {
      return _statusStrip(
        Icons.inbox_rounded,
        EduColors.onPrimary,
        'No modules added to this programme yet',
      );
    }

    final remaining = total - done;
    final percent = (done / total * 100).round();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Modules completed',
              style: TextStyle(color: EduColors.onPrimaryMuted, fontSize: 13),
            ),
            Text(
              '$done/$total  •  $percent%',
              style: const TextStyle(
                color: EduColors.onPrimary,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        _buildSegmentedProgress(done, total),
        const SizedBox(height: 14),
        remaining > 0
            ? _statusStrip(
          Icons.pending_actions_rounded,
          EduColors.accent,
          remaining == 1
              ? '1 module left to complete'
              : '$remaining modules left to complete',
        )
            : _statusStrip(
          Icons.check_circle_rounded,
          EduColors.success,
          'All caught up — no work pending',
        ),
      ],
    );
  }

  Widget _statusStrip(IconData icon, Color iconColor, String text) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: EduColors.onPrimaryFaint,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, color: iconColor, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                color: EduColors.onPrimary,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSegmentedProgress(int completed, int total) {
    // Too many modules → segments get too thin, use a plain bar instead.
    if (total > 24) {
      return TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: completed / total),
        duration: const Duration(milliseconds: 900),
        curve: Curves.easeOutCubic,
        builder: (context, v, _) => ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: v,
            minHeight: 8,
            color: EduColors.onPrimary,
            backgroundColor: EduColors.onPrimaryFaint,
          ),
        ),
      );
    }
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: completed / total),
      duration: const Duration(milliseconds: 900),
      curve: Curves.easeOutCubic,
      builder: (context, value, _) {
        final filledCount = (value * total).round();
        return Row(
          children: List.generate(total, (i) {
            final isFilled = i < filledCount;
            return Expanded(
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                height: 8,
                margin: EdgeInsets.only(right: i == total - 1 ? 0 : 3),
                decoration: BoxDecoration(
                  color: isFilled
                      ? EduColors.onPrimary
                      : EduColors.onPrimaryFaint,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            );
          }),
        );
      },
    );
  }

  Widget _buildStatChip(IconData icon, String value, String label) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
        decoration: BoxDecoration(
          color: EduColors.onPrimaryFaint,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            Icon(icon, color: EduColors.onPrimary, size: 18),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: const TextStyle(
                    color: EduColors.onPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  label,
                  style: const TextStyle(
                      color: EduColors.onPrimaryMuted, fontSize: 10),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ───────────────────────── Entry cards & notifications ─────────────────────────

  Widget _buildEntryCard({
    required IconData icon,
    required Color iconColor,
    required Color tint,
    required String title,
    required String subtitle,
    String? heroTag,
  }) {
    final iconBadge = Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: tint,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Icon(icon, color: iconColor, size: 24),
    );
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: EduColors.surface,
        borderRadius: BorderRadius.circular(18),
        boxShadow: _cardShadow,
      ),
      child: Row(
        children: [
          heroTag != null ? Hero(tag: heroTag, child: iconBadge) : iconBadge,
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: EduColors.textPrimary,
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(
                      color: EduColors.textSecondary, fontSize: 12),
                ),
              ],
            ),
          ),
          Container(
            width: 36,
            height: 36,
            decoration: const BoxDecoration(
              color: EduColors.primary,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.arrow_forward_rounded,
                color: EduColors.onPrimary, size: 18),
          ),
        ],
      ),
    );
  }

  Widget _buildNotifTile(_NotifData n) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: EduColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: EduColors.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: n.tint,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(n.icon, color: n.iconColor, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  n.title,
                  style: const TextStyle(
                    color: EduColors.textPrimary,
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  n.subtitle,
                  style: const TextStyle(
                      color: EduColors.textSecondary, fontSize: 12),
                ),
                const SizedBox(height: 4),
                Text(
                  n.time,
                  style: const TextStyle(
                      color: EduColors.textSecondary, fontSize: 11),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ───────────────────────── Helper widgets ─────────────────────────

/// Compresses its child slightly on press and springs back on release.
class _TapScale extends StatefulWidget {
  final Widget child;
  final VoidCallback onTap;

  const _TapScale({required this.child, required this.onTap});

  @override
  State<_TapScale> createState() => _TapScaleState();
}

class _TapScaleState extends State<_TapScale> {
  double _scale = 1.0;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _scale = 0.97),
      onTapUp: (_) => setState(() => _scale = 1.0),
      onTapCancel: () => setState(() => _scale = 1.0),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _scale,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOut,
        child: widget.child,
      ),
    );
  }
}

/// Pulsing placeholder block shown while the programme title loads.
class _ShimmerLine extends StatefulWidget {
  final double width;
  final double height;

  const _ShimmerLine({super.key, required this.width, this.height = 16});

  @override
  State<_ShimmerLine> createState() => _ShimmerLineState();
}

class _ShimmerLineState extends State<_ShimmerLine>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) => Opacity(
        opacity: 0.3 + (_controller.value * 0.5),
        child: child,
      ),
      child: Container(
        width: widget.width,
        height: widget.height,
        decoration: BoxDecoration(
          color: EduColors.onPrimaryFaint,
          borderRadius: BorderRadius.circular(6),
        ),
      ),
    );
  }
}

/// Pulsing accent dot on the notification bell.
class _PulseDot extends StatefulWidget {
  const _PulseDot();

  @override
  State<_PulseDot> createState() => _PulseDotState();
}

class _PulseDotState extends State<_PulseDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) => Transform.scale(
        scale: 0.9 + (_controller.value * 0.25),
        child: child,
      ),
      child: Container(
        width: 14,
        height: 14,
        decoration: BoxDecoration(
          color: EduColors.accent,
          shape: BoxShape.circle,
          border: Border.all(color: EduColors.background, width: 2),
        ),
      ),
    );
  }
}

/// Cascading entrance for the notification list in the bottom sheet.
class _AnimatedNotifList extends StatefulWidget {
  final List<_NotifData> notifications;
  final Widget Function(_NotifData) tileBuilder;

  const _AnimatedNotifList({
    required this.notifications,
    required this.tileBuilder,
  });

  @override
  State<_AnimatedNotifList> createState() => _AnimatedNotifListState();
}

class _AnimatedNotifListState extends State<_AnimatedNotifList>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 300 + widget.notifications.length * 80),
    )..forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(widget.notifications.length, (index) {
        final start = (index * 0.12).clamp(0.0, 0.8);
        final animation = CurvedAnimation(
          parent: _controller,
          curve: Interval(
            start,
            (start + 0.5).clamp(0.0, 1.0),
            curve: Curves.easeOutCubic,
          ),
        );
        return FadeTransition(
          opacity: animation,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, 0.15),
              end: Offset.zero,
            ).animate(animation),
            child: widget.tileBuilder(widget.notifications[index]),
          ),
        );
      }),
    );
  }
}

class _NotifData {
  final IconData icon;
  final Color iconColor;
  final Color tint;
  final String title;
  final String subtitle;
  final String time;

  _NotifData({
    required this.icon,
    required this.iconColor,
    required this.tint,
    required this.title,
    required this.subtitle,
    required this.time,
  });
}