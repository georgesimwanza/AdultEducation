import 'package:provider/provider.dart';
import 'package:adult/Controller/auth_controller.dart';
import 'package:adult/service/dashboard_service.dart';
import 'package:flutter/material.dart';
import './subject.dart';
import 'schedule_screen.dart';
import 'package:adult/service/sync_service.dart';
import 'package:adult/screens/color.dart';
import 'package:adult/Model/school_term.dart';

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
          final row = results.first;
          if (!mounted) return;
          setState(() {
            _programmeTitle = row['name'] as String;
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

  // ───────────────────────── Term progress helpers ─────────────────────────
  // Term dates come from `zambia2026TermsBestEffort` (Model/school_term.dart),
  // evaluated by computeTermProgress() — the same source the admin
  // dashboard uses, so both screens always agree.

  String _formatSpan(int days) {
    final d = days < 0 ? 0 : days;
    if (d >= 30) return '${(d / 30).round()} mo';
    return '$d d';
  }

  String _progressMessage(double p) {
    if (p >= 1) return 'Term complete — well done!';
    if (p >= 0.9) return 'Almost there, finish strong';
    if (p >= 0.5) return "You're making great progress";
    if (p >= 0.25) return 'Building momentum';
    return "You've just started — keep going";
  }

  // ───────────────────────── Data ─────────────────────────

  // Getter (not a field) so hot reload picks up changes to _NotifData.
  List<_NotifData> get _notifications => [
    _NotifData(
      icon: Icons.check_rounded,
      iconColor: EduColors.success,
      tint: EduColors.successSoft,
      title: 'Assignment graded',
      subtitle: 'Business Communication · 86%',
      time: '2h',
    ),
    _NotifData(
      icon: Icons.alarm_rounded,
      iconColor: EduColors.accent,
      tint: EduColors.accentSoft,
      title: 'Assignment due tomorrow',
      subtitle: 'Principles of Marketing',
      time: '5h',
    ),
    _NotifData(
      icon: Icons.play_circle_rounded,
      iconColor: EduColors.primary,
      tint: EduColors.primarySoft,
      title: 'New content available',
      subtitle: 'Video lectures for Module 5 uploaded',
      time: '1d',
    ),
  ];

  /// Up to two initials from the signed-in user's email (e.g. "tm" → "TM").
  /// Swap for the user's real name if AuthController exposes one.
  String _initials() {
    final email = context.read<AuthController>().currentUser?.email ?? '';
    final local = email.split('@').first;
    final parts =
    local.split(RegExp(r'[._\-\s]+')).where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return '?';
    if (parts.length == 1) {
      final p = parts.first;
      return (p.length >= 2 ? p.substring(0, 2) : p).toUpperCase();
    }
    return (parts[0][0] + parts[1][0]).toUpperCase();
  }

  String _timeGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }

  // ───────────────────────── Animation / navigation ─────────────────────────

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

  // ───────────────────────── Build ─────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: EduColors.background,
      body: SafeArea(
        child: RefreshIndicator(
          color: EduColors.primary,
          onRefresh: () async {
            setState(() => _isLoadingTitle = true);
            await _fetchTitle();
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _fadeSlideIn(start: 0.0, end: 0.5, child: _buildHeader()),
                const SizedBox(height: 20),
                _fadeSlideIn(
                    start: 0.08, end: 0.55, child: _buildSearchBar()),
                const SizedBox(height: 18),
                _fadeSlideIn(
                    start: 0.12, end: 0.6, child: _buildFilterChips()),
                const SizedBox(height: 20),
                _fadeSlideIn(
                    start: 0.18, end: 0.75, child: _buildCurrentProgramCard()),
                const SizedBox(height: 26),
                _fadeSlideIn(
                  start: 0.28,
                  end: 0.85,
                  child: _buildSectionTitle('Quick access'),
                ),
                const SizedBox(height: 12),
                _fadeSlideIn(
                  start: 0.32,
                  end: 0.9,
                  child: AnimatedSize(
                    duration: const Duration(milliseconds: 250),
                    curve: Curves.easeOut,
                    alignment: Alignment.topCenter,
                    child: IntrinsicHeight(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          if (_showCourses)
                            Expanded(
                              child: _TapScale(
                                onTap: _goToSubjects,
                                child: _buildQuickCard(
                                  icon: Icons.menu_book_rounded,
                                  iconColor: EduColors.primary,
                                  tint: EduColors.primarySoft,
                                  title: 'Browse Courses',
                                  subtitle: 'Explore new skills',
                                  heroTag: 'browse-courses-icon',
                                ),
                              ),
                            ),
                          if (_showCourses && _showSchedule)
                            const SizedBox(width: 12),
                          if (_showSchedule)
                            Expanded(
                              child: _TapScale(
                                onTap: _goToSchedule,
                                child: _buildQuickCard(
                                  icon: Icons.calendar_month_rounded,
                                  iconColor: EduColors.accent,
                                  tint: EduColors.accentSoft,
                                  title: 'Schedule',
                                  subtitle: 'Plan your week',
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
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
                    children:
                    _notifications.take(2).map(_buildNotifTile).toList(),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ───────────────────────── Header, search, chips ─────────────────────────

  Widget _buildHeader() {
    return Row(
      children: [
        Container(
          width: 48,
          height: 48,
          alignment: Alignment.center,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [EduColors.accent, Color(0xFFE5622B)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            shape: BoxShape.circle,
          ),
          child: Text(
            _initials(),
            style: const TextStyle(
              color: EduColors.onPrimary,
              fontSize: 15,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _timeGreeting(),
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
                const Positioned(top: 2, right: 2, child: _PulseDot()),
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
        height: 54,
        padding: const EdgeInsets.fromLTRB(16, 0, 8, 0),
        decoration: BoxDecoration(
          color: EduColors.surface,
          borderRadius: BorderRadius.circular(27),
          border: Border.all(color: EduColors.border),
        ),
        child: Row(
          children: [
            const Icon(Icons.search_rounded,
                color: EduColors.textSecondary, size: 22),
            const SizedBox(width: 10),
            const Expanded(
              child: Text(
                'Search courses, lessons…',
                style: TextStyle(color: EduColors.textSecondary, fontSize: 14),
              ),
            ),
            Container(
              width: 40,
              height: 40,
              decoration: const BoxDecoration(
                color: EduColors.primarySoft,
                shape: BoxShape.circle,
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
      height: 40,
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
              padding: const EdgeInsets.symmetric(horizontal: 22),
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
                      : EduColors.textPrimary,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
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
    final term = computeTermProgress(
      zambia2026TermsBestEffort,
      DateTime.now(),
    );
    final bool isHoliday = term.isHoliday;
    final String termLabel = term.label;
    final int daysLeft = (term.daysLeft as num).toInt();
    final double progress =
    isHoliday ? 0.0 : (term.percentComplete as num).toDouble();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [EduColors.primary, EduColors.primaryDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(26),
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
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: EduColors.onPrimaryFaint,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: EduColors.onPrimaryFaint),
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
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  color: EduColors.onPrimaryFaint,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(Icons.school_rounded,
                    color: EduColors.onPrimary, size: 26),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  child: _isLoadingTitle
                      ? const Align(
                    alignment: Alignment.centerLeft,
                    child: _ShimmerLine(
                        key: ValueKey('shimmer'), width: 160, height: 22),
                  )
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
              ),
            ],
          ),
          const SizedBox(height: 20),
          _buildTermProgress(
            label: termLabel,
            progress: progress,
            isHoliday: isHoliday,
            daysLeft: daysLeft,
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _buildStatChip(
                Icons.event_available_rounded,
                isHoliday ? 'Holiday' : 'Active',
                'Status',
              ),
              const SizedBox(width: 10),
              _buildStatChip(
                Icons.schedule_rounded,
                _formatSpan(daysLeft),
                isHoliday ? 'Until term starts' : 'Time left',
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Term label + percent, thin bar, and an encouragement strip.
  Widget _buildTermProgress({
    required String label,
    required double progress,
    required bool isHoliday,
    required int daysLeft,
  }) {
    if (_isLoadingTitle) {
      return const _ShimmerLine(
          key: ValueKey('p-shimmer'), width: double.infinity, height: 64);
    }

    final percent = (progress * 100).round();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                    color: EduColors.onPrimaryMuted, fontSize: 12),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              isHoliday ? 'On holiday' : '$percent%',
              style: const TextStyle(
                color: EduColors.onPrimary,
                fontSize: 12,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: progress),
          duration: const Duration(milliseconds: 900),
          curve: Curves.easeOutCubic,
          builder: (context, v, _) => ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: v,
              minHeight: 6,
              color: EduColors.onPrimary,
              backgroundColor: EduColors.onPrimaryFaint,
            ),
          ),
        ),
        const SizedBox(height: 14),
        _statusStrip(
          isHoliday ? Icons.beach_access_rounded : Icons.auto_awesome_rounded,
          isHoliday
              ? '$daysLeft days until term starts'
              : _progressMessage(progress),
        ),
      ],
    );
  }

  Widget _statusStrip(IconData icon, String text) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: const Color(0x26000000), // black @ 15% — darker inset strip
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: EduColors.onPrimaryFaint),
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: EduColors.accentSoft,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: EduColors.accent, size: 18),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                color: EduColors.onPrimary,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatChip(IconData icon, String value, String label) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
        decoration: BoxDecoration(
          color: const Color(0x1AFFFFFF),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: EduColors.onPrimaryFaint),
        ),
        child: Row(
          children: [
            Icon(icon, color: EduColors.onPrimary, size: 18),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    value,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: EduColors.onPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        color: EduColors.onPrimaryMuted, fontSize: 10),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ───────────────────────── Quick access & notifications ─────────────────────────

  Widget _buildQuickCard({
    required IconData icon,
    required Color iconColor,
    required Color tint,
    required String title,
    required String subtitle,
    String? heroTag,
  }) {
    final iconBadge = Container(
      width: 46,
      height: 46,
      decoration: BoxDecoration(
        color: tint,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Icon(icon, color: iconColor, size: 24),
    );
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: EduColors.surface,
        borderRadius: BorderRadius.circular(22),
        boxShadow: EduColors.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          heroTag != null ? Hero(tag: heroTag, child: iconBadge) : iconBadge,
          const SizedBox(height: 16),
          Text(
            title,
            style: const TextStyle(
              color: EduColors.textPrimary,
              fontWeight: FontWeight.w800,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: const TextStyle(
                color: EduColors.textSecondary, fontSize: 11),
          ),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerRight,
            child: Container(
              width: 34,
              height: 34,
              decoration: const BoxDecoration(
                color: EduColors.primary,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.chevron_right_rounded,
                  color: EduColors.onPrimary, size: 20),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotifTile(_NotifData n) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: EduColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: EduColors.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: n.tint,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(n.icon, color: n.iconColor, size: 22),
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
                const SizedBox(height: 3),
                Text(
                  n.subtitle,
                  style: const TextStyle(
                      color: EduColors.textSecondary, fontSize: 12),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            n.time,
            style: const TextStyle(
              color: EduColors.textSecondary,
              fontSize: 11,
              fontWeight: FontWeight.w700,
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

/// Pulsing placeholder block shown while data loads.
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
          borderRadius: BorderRadius.circular(8),
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
        width: 11,
        height: 11,
        decoration: BoxDecoration(
          color: EduColors.accent,
          shape: BoxShape.circle,
          border: Border.all(color: EduColors.surface, width: 2),
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