import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:adult/Service/user_service.dart';
import 'package:adult/service/sync_service.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final UserService _userService = UserService();
  String _totalStudents = '...';
  String _institutionName = 'Loading...';
  bool _fetched = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_fetched) {
      _fetched = true;
      _fetchStudentCount();
      _fetchInstitutionName();
    }
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

  /// Mirrors the same local-db-first pattern used for programme titles in
  /// the student-facing Dashboard (Dashboard._fetchTitle). No confirmed
  /// server endpoint for institution name exists yet, so this only checks
  /// local storage — if it's not synced there, it falls back to a
  /// placeholder rather than guessing at an API call.
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
    final recentActivity = [
      {
        'action': 'New student enrolled',
        'name': 'Sarah Johnson',
        'time': '5 min ago',
      },
      {
        'action': 'Content uploaded',
        'name': 'Math Module 5',
        'time': '12 min ago',
      },
      {
        'action': 'Subject updated',
        'name': 'Physics 101',
        'time': '1 hour ago',
      },
      {'action': 'Admin added', 'name': 'John Smith', 'time': '2 hours ago'},
    ];

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
                ],
              ),
              const SizedBox(height: 24),
              _buildStudentCountCard(),
              const SizedBox(height: 16),
              _buildTermCard(),
              const SizedBox(height: 20),
              _buildRecentActivityCard(recentActivity),
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
        ],
      ),
    );
  }

  /// Static placeholder — no term-tracking data source exists in this app
  /// yet. Swap these values for a real fetch once there's an endpoint.
  Widget _buildTermCard() {
    const daysLeft = 69;
    const percentComplete = 0.13;

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
              const Row(
                children: [
                  Icon(
                    Icons.calendar_today_rounded,
                    color: Colors.white70,
                    size: 16,
                  ),
                  SizedBox(width: 8),
                  Text(
                    'Term 3 (2025/2026)',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  'Active',
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          const Text(
            '$daysLeft days left in term',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: percentComplete,
              minHeight: 6,
              backgroundColor: const Color(0xFF3A3A3A),
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${(percentComplete * 100).round()}% complete',
            style: const TextStyle(color: Color(0xFFB3B3B3), fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentActivityCard(List<Map<String, String>> recentActivity) {
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
          ...recentActivity.asMap().entries.map((entry) {
            final i = entry.key;
            final activity = entry.value;
            return Column(
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: Colors.black,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            activity['action']!,
                            style: const TextStyle(
                              fontSize: 14,
                              color: Colors.black,
                            ),
                          ),
                          Text(
                            activity['name']!,
                            style: const TextStyle(
                              fontSize: 13,
                              color: Colors.black54,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      activity['time']!,
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
