import 'package:provider/provider.dart';
import 'package:adult/Controller/auth_controller.dart';
import 'package:adult/service/dashboard_service.dart';
import 'package:flutter/material.dart';
import './subject.dart';
import 'schedule_screen.dart';
import 'package:adult/service/sync_service.dart';

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

  // Tied together — the segmented bar below reflects these same numbers
  // instead of a separate hardcoded percentage.
  static const int _modulesCompleted = 12;
  static const int _modulesTotal = 18;

  // Drives the staggered entrance animation for every section on the page.
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
        setState(() {
          _programmeTitle = 'No programme selected';
          _isLoadingTitle = false;
        });
        return;
      }

      // ← try local storage first
      final db = context.read<SyncService>().db;
      if (db != null) {
        final results = await db.query(
          'programmes',
          where: 'id = ?',
          whereArgs: [programmeId],
        );
        if (results.isNotEmpty) {
          print('📦 Loaded programme title from local storage');
          setState(() {
            _programmeTitle = results.first['name'] as String;
            _isLoadingTitle = false;
          });
          return;
        }
      }

      // ← fall back to server if not in local storage
      print('🌐 Programme not in local storage — fetching from server');
      final title = await DashboardService().getProgramTitle(programmeId);
      setState(() {
        _programmeTitle = title;
        _isLoadingTitle = false;
      });
    } catch (e) {
      setState(() {
        _programmeTitle = 'Failed to load';
        _isLoadingTitle = false;
      });
    }
  }

  static const List<BoxShadow> _cardShadow = [
    BoxShadow(
      color: Color(0x1A000000),
      blurRadius: 12,
      spreadRadius: 0,
      offset: Offset(0, 4),
    ),
  ];

  final List<_NotifData> _notifications = [
    _NotifData(
      icon: Icons.check_circle_rounded,
      iconColor: Colors.black,
      title: 'Assignment Graded',
      subtitle: 'Social Media Campaign – Score: 95/100',
      time: '2 hours ago',
    ),
    _NotifData(
      icon: Icons.warning_amber_rounded,
      iconColor: Colors.black,
      title: 'Upcoming Deadline',
      subtitle: 'Module 4 quiz due in 3 days',
      time: '5 hours ago',
    ),
    _NotifData(
      icon: Icons.info_rounded,
      iconColor: Colors.black,
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

  /// Wraps [child] in a fade + upward-slide animation that plays as part
  /// of the page's staggered entrance. [start]/[end] are 0–1 positions
  /// within `_entranceController`'s timeline, so different sections can
  /// animate in slightly offset from one another (Classroom-style cascade).
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

  /// Fade + slight-slide page transition, used instead of the default
  /// hard-cut MaterialPageRoute for a softer, more Classroom-like feel.
  Route _fadeRoute(Widget page) {
    return PageRouteBuilder(
      transitionDuration: const Duration(milliseconds: 280),
      pageBuilder: (_, __, ___) => page,
      transitionsBuilder: (_, animation, __, child) {
        final curved = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOut,
        );
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

  void _openNotifications() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.of(context).viewInsets.bottom + 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Notifications',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: Colors.black,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.black54),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: SafeArea(
        child: RefreshIndicator(
          color: Colors.black,
          onRefresh: () async {
            setState(() => _isLoadingTitle = true);
            await _fetchTitle();
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _fadeSlideIn(start: 0.0, end: 0.5, child: _buildTopBar()),
                const SizedBox(height: 20),
                _fadeSlideIn(
                  start: 0.05,
                  end: 0.55,
                  child: Text(
                    '${_timeGreeting()} 👋',
                    style: const TextStyle(
                      color: Colors.black54,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                _fadeSlideIn(
                  start: 0.05,
                  end: 0.55,
                  child: const Text(
                    'Learn At Your\nOwn Pace',
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                      height: 1.2,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                _fadeSlideIn(
                  start: 0.1,
                  end: 0.6,
                  child: _buildFilterChips(),
                ),
                const SizedBox(height: 16),
                _fadeSlideIn(
                  start: 0.15,
                  end: 0.75,
                  child: _buildCurrentProgramCard(),
                ),
                const SizedBox(height: 16),
                _fadeSlideIn(
                  start: 0.25,
                  end: 0.85,
                  child: _TapScale(
                    onTap: () => Navigator.push(
                      context,
                      _fadeRoute(
                        ChangeNotifierProvider.value(
                          value: context.read<AuthController>(),
                          child: SubjectPage(),
                        ),
                      ),
                    ),
                    child: _buildEntryCard(
                      icon: Icons.menu_book_rounded,
                      iconColor: Colors.black,
                      title: 'Browse Courses',
                      subtitle: 'Explore new programs',
                      heroTag: 'browse-courses-icon',
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                _fadeSlideIn(
                  start: 0.3,
                  end: 0.9,
                  child: _TapScale(
                    onTap: () => Navigator.push(
                      context,
                      _fadeRoute(
                        ChangeNotifierProvider.value(
                          value: context.read<AuthController>(),
                          child: ScheduleScreen(),
                        ),
                      ),
                    ),
                    child: _buildEntryCard(
                      icon: Icons.calendar_month_rounded,
                      iconColor: Colors.black,
                      title: 'Schedule',
                      subtitle: 'View your timetable',
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: const BoxDecoration(
                color: Colors.black,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.person, color: Colors.white, size: 20),
            ),
          ],
        ),
        GestureDetector(
          onTap: _openNotifications,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: const BoxDecoration(
                  color: Colors.black,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.notifications_none_rounded,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              if (_notifications.isNotEmpty)
                Positioned(
                  top: -2,
                  right: -2,
                  child: _PulseDot(),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFilterChips() {
    return SizedBox(
      height: 36,
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
              padding: const EdgeInsets.symmetric(horizontal: 18),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: isSelected ? Colors.black : Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isSelected ? Colors.black : const Color(0xFFDDDDDD),
                ),
              ),
              child: AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 200),
                style: TextStyle(
                  color: isSelected ? Colors.white : Colors.black87,
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

  Widget _buildCurrentProgramCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF111111),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: const Color(0xFF262626),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.school_rounded,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Current Program',
                      style: TextStyle(
                        color: Color(0xFF9E9E9E),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    // Shimmer skeleton while the programme title loads,
                    // then a soft cross-fade into the real text.
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 300),
                      child: _isLoadingTitle
                          ? const _ShimmerLine(
                        key: ValueKey('shimmer'),
                        width: 140,
                        height: 18,
                      )
                          : Text(
                        _programmeTitle,
                        key: const ValueKey('title'),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Modules Completed',
                style: TextStyle(color: Color(0xFF9E9E9E), fontSize: 13),
              ),
              Text(
                '$_modulesCompleted/$_modulesTotal',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          _buildSegmentedProgress(_modulesCompleted, _modulesTotal),
          const SizedBox(height: 16),
          Row(
            children: [
              _buildStatChipDark(Icons.access_time, '6 mo', 'Duration'),
              const SizedBox(width: 8),
              _buildStatChipDark(Icons.hourglass_bottom, '2 mo', 'Time Left'),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              const Icon(Icons.circle, color: Colors.white, size: 8),
              const SizedBox(width: 6),
              const Expanded(
                child: Text(
                  'Module 4 of 6 • Due April 25, 2026',
                  style: TextStyle(color: Color(0xFF9E9E9E), fontSize: 12),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Row of small rounded blocks — filled ones represent completed
  /// modules. Animates from empty to the real completion ratio on load
  /// instead of appearing fully filled.
  Widget _buildSegmentedProgress(int completed, int total) {
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
                margin: EdgeInsets.only(right: i == total - 1 ? 0 : 4),
                decoration: BoxDecoration(
                  color: isFilled ? Colors.white : const Color(0xFF2E2E2E),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            );
          }),
        );
      },
    );
  }

  Widget _buildStatChipDark(IconData icon, String value, String label) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: const Color(0xFF1E1E1E),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFF2E2E2E)),
        ),
        child: Column(
          children: [
            Icon(icon, color: Colors.white70, size: 16),
            const SizedBox(height: 6),
            Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              label,
              style: const TextStyle(color: Color(0xFF9E9E9E), fontSize: 10),
            ),
          ],
        ),
      ),
    );
  }

  /// Note: navigation + tap-scale are now applied by the caller via
  /// `_TapScale`, so this just builds the visual card. The inner
  /// "Enter" button still works as a secondary explicit tap target.
  Widget _buildEntryCard({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    String? heroTag,
  }) {
    final iconBadge = Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.08),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Icon(icon, color: iconColor, size: 20),
    );
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: _cardShadow,
      ),
      child: Row(
        children: [
          // Herod on the "Browse Courses" card so the icon visibly
          // flies into SubjectPage's header icon on navigation.
          heroTag != null ? Hero(tag: heroTag, child: iconBadge) : iconBadge,
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  ),
                ),
                Text(
                  subtitle,
                  style: const TextStyle(color: Colors.black45, fontSize: 12),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.black,
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Text(
              'Enter',
              style: TextStyle(fontSize: 13, color: Colors.white),
            ),
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
        color: const Color(0xFFF7F7F7),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(n.icon, color: n.iconColor, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  n.title,
                  style: const TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  n.subtitle,
                  style: const TextStyle(color: Colors.black54, fontSize: 12),
                ),
                const SizedBox(height: 4),
                Text(
                  n.time,
                  style: const TextStyle(color: Colors.black38, fontSize: 11),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Compresses its child slightly on press and springs back on release —
/// the small tactile "give" that makes Classroom cards feel responsive.
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

/// A pulsing gray placeholder block, standing in for content that's
/// still loading — used for the programme title while it's being fetched.
class _ShimmerLine extends StatefulWidget {
  final double width;
  final double height;

  const _ShimmerLine({
    super.key,
    required this.width,
    this.height = 16,
  });

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
        opacity: 0.3 + (_controller.value * 0.4),
        child: child,
      ),
      child: Container(
        width: widget.width,
        height: widget.height,
        decoration: BoxDecoration(
          color: const Color(0xFF3A3A3A),
          borderRadius: BorderRadius.circular(4),
        ),
      ),
    );
  }
}

/// The small dot on the notification bell, gently pulsing to draw the
/// eye without needing a color change.
class _PulseDot extends StatefulWidget {
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
      builder: (context, child) {
        final scale = 0.9 + (_controller.value * 0.25);
        return Transform.scale(scale: scale, child: child);
      },
      child: Container(
        width: 14,
        height: 14,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          border: Border.all(color: const Color(0xFFF5F5F5), width: 2),
        ),
        child: Container(
          margin: const EdgeInsets.all(3),
          decoration: const BoxDecoration(
            color: Colors.black,
            shape: BoxShape.circle,
          ),
        ),
      ),
    );
  }
}

/// Plays each notification tile in with a slight delay after the one
/// before it — the same cascade feel as the dashboard's own entrance,
/// applied to the bottom sheet's list.
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
      duration: Duration(
        milliseconds: 300 + widget.notifications.length * 80,
      ),
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
  final String title;
  final String subtitle;
  final String time;

  _NotifData({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.time,
  });
}