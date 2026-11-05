import 'package:adult/core/responsive.dart';
import 'package:flutter/material.dart';
import 'package:adult/screens/color.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common/sqlite_api.dart';
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
      backgroundColor: EduColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: ResponsiveCenter(child: Column(
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
                            color: EduColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _formattedDate(),
                          style: const TextStyle(
                            fontSize: 13,
                            color: EduColors.textSecondary,
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
                          color: EduColors.primary,
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
                            border: Border.all(color: EduColors.primary, width: 1.2),
                          ),
                          child: const Icon(
                            Icons.notifications_none_rounded,
                            size: 12,
                            color: EduColors.primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 24),
              if (context.isDesktop)
                // Stats on the left, recent activity beside them.
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        children: [
                          _buildStudentCountCard(),
                          const SizedBox(height: 16),
                          _buildTermCard(),
                        ],
                      ),
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      child: _buildRecentActivityCard(_recentActivity),
                    ),
                  ],
                )
              else if (context.isTablet) ...[
                IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(child: _buildStudentCountCard()),
                      const SizedBox(width: 16),
                      Expanded(child: _buildTermCard()),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                _buildRecentActivityCard(_recentActivity),
              ] else ...[
              _buildStudentCountCard(),
              const SizedBox(height: 16),
              _buildTermCard(),
              const SizedBox(height: 20),
              _buildRecentActivityCard(_recentActivity),
              ],
            ],
          )),
        ),
      ),
    );
  }

  Widget _buildStudentCountCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: EduColors.surface,
        borderRadius: BorderRadius.circular(22),
        boxShadow: EduColors.cardShadow,
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: EduColors.primary,
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
                    color: EduColors.textPrimary,
                  ),
                ),
                const Text(
                  'Students',
                  style: TextStyle(fontSize: 13, color: EduColors.textSecondary),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: EduColors.textSecondary),
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
        color: EduColors.primary.withOpacity(opacity),
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }

  /// Uses the app's design tokens (see the
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
        gradient: const LinearGradient(
          colors: [EduColors.primary, EduColors.primaryDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: EduColors.cardShadow,
        borderRadius: BorderRadius.circular(24),
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
                    color: EduColors.textPrimary,
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
              backgroundColor: EduColors.onPrimaryFaint,
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            progress.isHoliday
                ? 'On holiday'
                : '${(progress.percentComplete * 100).round()}% complete',
            style: const TextStyle(color: EduColors.onPrimaryMuted, fontSize: 12),
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
        color: EduColors.surface,
        borderRadius: BorderRadius.circular(22),
        boxShadow: EduColors.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.bolt_rounded, color: EduColors.primary, size: 20),
              SizedBox(width: 8),
              Text(
                'Recent Activity',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: EduColors.textPrimary,
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
                style: TextStyle(fontSize: 13, color: EduColors.textSecondary),
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
                          color: EduColors.border,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          _activityIcons[activity.icon] ??
                              Icons.circle_outlined,
                          size: 15,
                          color: EduColors.primary,
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
                                color: EduColors.textPrimary,
                              ),
                            ),
                            Text(
                              activity.name,
                              style: const TextStyle(
                                fontSize: 13,
                                color: EduColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        _timeAgo(activity.timestamp),
                        style: const TextStyle(
                          fontSize: 11,
                          color: EduColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                  if (i < recentActivity.length - 1)
                    const Divider(height: 20, color: EduColors.border),
                ],
              );
            }),
        ],
      ),
    );
  }
}
