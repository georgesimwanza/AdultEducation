import 'package:provider/provider.dart';
import 'package:adult/Controller/auth_controller.dart';
import 'package:adult/service/dashboard_service.dart';
import 'package:flutter/material.dart';
import './subject.dart';
import 'schedule_screen.dart';

class Dashboard extends StatefulWidget {
  const Dashboard({super.key});

  @override
  State<Dashboard> createState() => DashboardState();
}

class DashboardState extends State<Dashboard> {
  int _selectedIndex = 0;
  String _programmeTitle = 'Loading...';
  bool _titleFetched = false; // prevent duplicate calls

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
      final programmeId = controller.currentUser?.programmeId;

      print('>>> Dashboard programmeId: $programmeId');

      if (programmeId == null) {
        setState(() => _programmeTitle = 'No programme selected');
        return;
      }

      final title = await DashboardService().getProgramTitle(programmeId);
      setState(() => _programmeTitle = title);
    } catch (e) {
      print('>>> Dashboard error: $e');
      setState(() => _programmeTitle = 'Failed to load');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Header ──
              const Text(
                'Dashboard',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Track your learning journey',
                style: TextStyle(color: Colors.grey, fontSize: 13),
              ),
              const SizedBox(height: 16),

              // ── Current Program Card ──
              _buildCurrentProgramCard(),
              const SizedBox(height: 16),

              // ── Browse Courses ──
              _buildEntryCard(
                icon: Icons.menu_book_rounded,
                iconColor: const Color(0xFF5B6EF5),
                title: 'Browse Courses',
                subtitle: 'Explore new programs',
              ),
              const SizedBox(height: 12),

              // ── Schedule ──
              _buildEntryCard(
                icon: Icons.calendar_month_rounded,
                iconColor: const Color(0xFF3DBE7A),
                title: 'Schedule',
                subtitle: 'View your timetable',
              ),
              const SizedBox(height: 24),

              // ── Notifications ──
              _buildNotificationsSection(),
              const SizedBox(height: 24),

              // ── Upcoming Classes ──
              _buildUpcomingClassesSection(),
            ],
          ),
        ),
      ),

      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (i) => setState(() => _selectedIndex = i),
        backgroundColor: const Color(0xFF1A1A1A),
        selectedItemColor: Colors.white,
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_rounded),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.book_rounded),
            label: 'Courses',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_rounded),
            label: 'Profile',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.menu_rounded),
            label: 'Menu',
          ),
        ],
      ),
    );
  }

  Widget _buildCurrentProgramCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Current Program',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            _programmeTitle,
            style: TextStyle(color: Colors.grey, fontSize: 13),
          ),
          const SizedBox(height: 16),

          // Progress
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
              Text(
                'Overall Progress',
                style: TextStyle(color: Colors.grey, fontSize: 13),
              ),
              Text('68%', style: TextStyle(color: Colors.white, fontSize: 13)),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: 0.68,
              minHeight: 6,
              backgroundColor: const Color(0xFF333333),
              valueColor: const AlwaysStoppedAnimation<Color>(
                Color(0xFF5B6EF5),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Stats Row
          Row(
            children: [
              _buildStatChip(Icons.access_time, '6 mo', 'Duration'),
              const SizedBox(width: 8),
              _buildStatChip(Icons.hourglass_bottom, '2 mo', 'Time Left'),
              const SizedBox(width: 8),
              _buildStatChip(Icons.play_arrow_rounded, '12/18', 'Complete'),
            ],
          ),
          const SizedBox(height: 16),

          // Current Module
          const Text(
            'Current Module',
            style: TextStyle(color: Colors.grey, fontSize: 12),
          ),
          const SizedBox(height: 4),
          Text(
            _programmeTitle,
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: Color(0xFF3DBE7A),
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 6),
              const Text(
                'Module 4 of 6 • Due April 25, 2026',
                style: TextStyle(color: Colors.grey, fontSize: 12),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Continue Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
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
              icon: const Icon(Icons.play_arrow_rounded, size: 18),
              label: const Text('Continue Learning'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2A2A2A),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
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
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFF2A2A2A),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(icon, color: Colors.white70, size: 18),
            const SizedBox(height: 6),
            Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              label,
              style: const TextStyle(color: Colors.grey, fontSize: 11),
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
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.15),
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
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  ),
                ),
                Text(
                  subtitle,
                  style: const TextStyle(color: Colors.grey, fontSize: 12),
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
                    value: context
                        .read<AuthController>(), // pass existing instance
                    child: title == 'Browse Courses'
                        ? SubjectPage()
                        : ScheduleScreen(),
                  ),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2A2A2A),
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

  Widget _buildNotificationsSection() {
    final notifications = [
      _NotifData(
        icon: Icons.check_circle_rounded,
        iconColor: const Color(0xFF3DBE7A),
        title: 'Assignment Graded',
        subtitle: 'Social Media Campaign – Score: 95/100',
        time: '2 hours ago',
      ),
      _NotifData(
        icon: Icons.warning_amber_rounded,
        iconColor: const Color(0xFFFFC107),
        title: 'Upcoming Deadline',
        subtitle: 'Module 4 quiz due in 3 days',
        time: '5 hours ago',
      ),
      _NotifData(
        icon: Icons.info_rounded,
        iconColor: const Color(0xFF5B6EF5),
        title: 'New Content Available',
        subtitle: 'Video lectures for Module 5 uploaded',
        time: '1 day ago',
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ...notifications.map((n) => _buildNotifTile(n)),
        const SizedBox(height: 8),
        Center(
          child: TextButton(
            onPressed: () {},
            child: const Text(
              'View All Notifications',
              style: TextStyle(color: Colors.grey),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildNotifTile(_NotifData n) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
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
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  n.subtitle,
                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                ),
                const SizedBox(height: 4),
                Text(
                  n.time,
                  style: const TextStyle(color: Colors.grey, fontSize: 11),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUpcomingClassesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'New Content',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          'view the new Content',
          style: TextStyle(color: Colors.grey, fontSize: 13),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF1E1E1E),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Expanded(
                    child: Text(
                      'Wrestlemania watch along',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF2A2A2A),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      'Live Session',
                      style: TextStyle(color: Colors.white, fontSize: 11),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              const Text(
                'Mr. Simwanza',
                style: TextStyle(color: Colors.grey, fontSize: 13),
              ),
              const SizedBox(height: 10),
              Row(
                children: const [
                  Icon(
                    Icons.calendar_today_rounded,
                    color: Colors.grey,
                    size: 14,
                  ),
                  SizedBox(width: 6),
                  Text(
                    'April 18, 2026',
                    style: TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                children: const [
                  Icon(Icons.access_time_rounded, color: Colors.grey, size: 14),
                  SizedBox(width: 6),
                  Text(
                    '6:00 PM – 8:00 PM EST',
                    style: TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
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
