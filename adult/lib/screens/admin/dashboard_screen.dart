import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';
import 'package:adult/Service/user_service.dart';
import 'package:adult/service/sync_service.dart';
import 'package:adult/service/institution_service.dart';
import 'package:adult/service/activity_log_service.dart';
import 'package:adult/Model/school_term.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final UserService _userService = UserService();
  final InstitutionService _institutionService = InstitutionService();
  String _totalStudents = '...';
  String _institutionName = 'Loading...';
  List<ActivityLogEntry> _recentActivity = [];
  bool _fetched = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_fetched) {
      _fetched = true;
      _fetchStudentCount();
      _fetchInstitutionName();
      _fetchRecentActivity();
    }
  }

  Future<void> _fetchRecentActivity() async {
    final db = context.read<SyncService>().db;
    if (db == null) return;
    final entries = await ActivityLogService(db: db).recent(limit: 10);
    if (mounted) setState(() => _recentActivity = entries);
  }

  String _timeAgo(DateTime time) {
    final diff = DateTime.now().difference(time);
    if (diff.inMinutes < 1) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes} min ago';
    if (diff.inHours < 24)
      return '${diff.inHours} hour${diff.inHours == 1 ? '' : 's'} ago';
    return '${diff.inDays} day${diff.inDays == 1 ? '' : 's'} ago';
  }

  Future<void> _fetchStudentCount() async {
    try {
      final count = await _userService.countStudentsByInstitution();
      setState(() {
        _totalStudents = count.toString();
      });
    } catch (e) {
      setState(() {
        _totalStudents = 'N/A';
      });
    }
  }

  /// Local-db-first: check the cache first, and if it's not there yet,
  /// fetch the real name from the backend and cache it for next time —
  /// same pattern as QuizService/AnnouncementService.
  Future<void> _fetchInstitutionName() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final institutionId = prefs.getInt('institution');
      if (institutionId == null) {
        setState(() => _institutionName = 'Institution');
        return;
      }

      final db = context.read<SyncService>().db;
      if (db != null) {
        final results = await db.query(
          'institutions',
          where: 'id = ?',
          whereArgs: [institutionId],
        );
        if (results.isNotEmpty) {
          setState(() => _institutionName = results.first['name'] as String);
          return;
        }
      }

      final name = await _institutionService.getInstitutionName(institutionId);
      if (name != null) {
        setState(() => _institutionName = name);
        if (db != null) {
          await db.insert('institutions', {
            'id': institutionId,
            'name': name,
          }, conflictAlgorithm: ConflictAlgorithm.replace);
        }
        return;
      }

      setState(() => _institutionName = 'Institution');
    } catch (e) {
      setState(() => _institutionName = 'Institution');
    }
  }

  String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }

  String _formattedDate() {
    const weekdays = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday',
    ];
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    final now = DateTime.now();
    return '${weekdays[now.weekday - 1]}, ${now.day} ${months[now.month - 1]} ${now.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${_greeting()}, $_institutionName 👋',
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            color: Colors.black,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _formattedDate(),
                          style: const TextStyle(
                            fontSize: 13,
                            color: Colors.black54,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: const BoxDecoration(
                          color: Colors.black,
                          shape: BoxShape.circle,
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          _institutionName.isNotEmpty
                              ? _institutionName[0].toUpperCase()
                              : '?',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            fontSize: 16,
                          ),
                        ),
                      ),
                      // Notification bell badge — from the reference screenshot.
                      // No notifications data source exists yet, so this is
                      // just the icon/affordance; wire up a real unread count
                      // and onTap once there's something to show.
                      Positioned(
                        top: -4,
                        right: -4,
                        child: Container(
                          width: 20,
                          height: 20,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.black, width: 1.2),
                          ),
                          child: const Icon(
                            Icons.notifications_none_rounded,
                            size: 12,
                            color: Colors.black,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 24),
              _buildStudentCountCard(),
              const SizedBox(height: 16),
              _buildTermCard(),
              const SizedBox(height: 20),
              _buildRecentActivityCard(_recentActivity),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStudentCountCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F7F7),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE4E4E4)),
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: Colors.black,
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.people_rounded,
              color: Colors.white,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _totalStudents,
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    color: Colors.black,
                  ),
                ),
                const Text(
                  'Students',
                  style: TextStyle(fontSize: 13, color: Colors.black54),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: Colors.black54),
            onPressed: () {
              setState(() => _totalStudents = '...');
              _fetchStudentCount();
            },
          ),
          const SizedBox(width: 4),
          // Decorative mini bar chart, from the reference screenshot — not
          // backed by real trend data yet, just the visual affordance.
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              _miniBar(height: 8, opacity: 0.25),
              const SizedBox(width: 3),
              _miniBar(height: 16, opacity: 0.5),
              const SizedBox(width: 3),
              _miniBar(height: 26, opacity: 1),
            ],
          ),
        ],
      ),
    );
  }

  Widget _miniBar({required double height, required double opacity}) {
    return Container(
      width: 5,
      height: height,
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(opacity),
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }

  /// Colors kept strictly black/white/grey — no accent colors (see the
  /// "Active" badge and progress bar below).
  Widget _buildTermCard() {
    final progress = computeTermProgress(
      zambia2026TermsBestEffort,
      DateTime.now(),
    );

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    const Icon(
                      Icons.calendar_today_rounded,
                      color: Colors.white70,
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        progress.label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  progress.isHoliday ? 'Holiday' : 'Active',
                  style: const TextStyle(
                    color: Colors.black,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Text(
            progress.isHoliday
                ? '${progress.daysLeft} days until term starts'
                : '${progress.daysLeft} days left in term',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress.isHoliday ? 0 : progress.percentComplete,
              minHeight: 6,
              backgroundColor: const Color(0xFF3A3A3A),
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            progress.isHoliday
                ? 'On holiday'
                : '${(progress.percentComplete * 100).round()}% complete',
            style: const TextStyle(color: Color(0xFFB3B3B3), fontSize: 12),
          ),
        ],
      ),
    );
  }

  static const Map<String, IconData> _activityIcons = {
    'person': Icons.person_outline_rounded,
    'document': Icons.description_outlined,
    'gear': Icons.settings_outlined,
    'shield': Icons.shield_outlined,
  };

  Widget _buildRecentActivityCard(List<ActivityLogEntry> recentActivity) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0D000000),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
        border: Border.all(color: const Color(0xFFF0F0F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.bolt_rounded, color: Colors.black, size: 20),
              SizedBox(width: 8),
              Text(
                'Recent Activity',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Colors.black,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (recentActivity.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Text(
                'Nothing yet — actions you take will show up here.',
                style: TextStyle(fontSize: 13, color: Colors.black45),
              ),
            )
          else
            ...recentActivity.asMap().entries.map((entry) {
              final i = entry.key;
              final activity = entry.value;
              return Column(
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 30,
                        height: 30,
                        decoration: BoxDecoration(
                          color: const Color(0xFFF3F4F6),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          _activityIcons[activity.icon] ??
                              Icons.circle_outlined,
                          size: 15,
                          color: Colors.black,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              activity.action,
                              style: const TextStyle(
                                fontSize: 14,
                                color: Colors.black,
                              ),
                            ),
                            Text(
                              activity.name,
                              style: const TextStyle(
                                fontSize: 13,
                                color: Colors.black54,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        _timeAgo(activity.timestamp),
                        style: const TextStyle(
                          fontSize: 11,
                          color: Colors.black38,
                        ),
                      ),
                    ],
                  ),
                  if (i < recentActivity.length - 1)
                    const Divider(height: 20, color: Color(0xFFF3F4F6)),
                ],
              );
            }),
        ],
      ),
    );
  }
}
