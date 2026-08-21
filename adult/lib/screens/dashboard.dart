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

class DashboardState extends State<Dashboard> {
  String _programmeTitle = 'Loading...';
  bool _titleFetched = false;
  int _selectedFilter = 0;

  static const List<String> _filters = ['All', 'Courses', 'Schedule'];

  // Tied together — the segmented bar below reflects these same numbers
  // instead of a separate hardcoded percentage.
  static const int _modulesCompleted = 12;
  static const int _modulesTotal = 18;

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
        setState(() => _programmeTitle = 'No programme selected');
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
          setState(() => _programmeTitle = results.first['name'] as String);
          return;
        }
      }

      // ← fall back to server if not in local storage
      print('🌐 Programme not in local storage — fetching from server');
      final title = await DashboardService().getProgramTitle(programmeId);
      setState(() => _programmeTitle = title);
    } catch (e) {
      setState(() => _programmeTitle = 'Failed to load');
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
              ..._notifications.map((n) => _buildNotifTile(n)),
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
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildTopBar(),
              const SizedBox(height: 20),
              const Text(
                'Learn At Your\nOwn Pace',
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  height: 1.2,
                ),
              ),
              const SizedBox(height: 16),
              _buildFilterChips(),
              const SizedBox(height: 16),
              _buildCurrentProgramCard(),
              const SizedBox(height: 16),
              _buildEntryCard(
                icon: Icons.menu_book_rounded,
                iconColor: Colors.black,
                title: 'Browse Courses',
                subtitle: 'Explore new programs',
              ),
              const SizedBox(height: 12),
              _buildEntryCard(
                icon: Icons.calendar_month_rounded,
                iconColor: Colors.black,
                title: 'Schedule',
                subtitle: 'View your timetable',
              ),
            ],
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
                  child: Container(
                    width: 14,
                    height: 14,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: const Color(0xFFF5F5F5),
                        width: 2,
                      ),
                    ),
                    child: Container(
                      margin: const EdgeInsets.all(3),
                      decoration: const BoxDecoration(
                        color: Colors.black,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
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
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 18),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: isSelected ? Colors.black : Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isSelected ? Colors.black : const Color(0xFFDDDDDD),
                ),
              ),
              child: Text(
                _filters[index],
                style: TextStyle(
                  color: isSelected ? Colors.white : Colors.black87,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
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
                    const SizedBox(height: 2),
                    Text(
                      _programmeTitle,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
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
              const SizedBox(width: 8),
              _buildStatChipDark(
                Icons.play_arrow_rounded,
                '$_modulesCompleted/$_modulesTotal',
                'Complete',
              ),
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
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ChangeNotifierProvider.value(
                      value: context.read<AuthController>(),
                      child: SubjectPage(),
                    ),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(vertical: 13),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
              child: const Text(
                'See More',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Row of small rounded blocks — filled ones represent completed
  /// modules, replacing the plain linear percentage bar.
  Widget _buildSegmentedProgress(int completed, int total) {
    return Row(
      children: List.generate(total, (i) {
        final isFilled = i < completed;
        return Expanded(
          child: Container(
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

  Widget _buildEntryCard({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: _cardShadow,
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.08),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
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
          ElevatedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ChangeNotifierProvider.value(
                    value: context.read<AuthController>(),
                    child: title == 'Browse Courses'
                        ? SubjectPage()
                        : ScheduleScreen(),
                  ),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.black,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
            child: const Text('Enter', style: TextStyle(fontSize: 13)),
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
