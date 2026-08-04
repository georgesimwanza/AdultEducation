import 'package:flutter/material.dart';
import 'package:adult/Service/user_service.dart';
import 'students_screen.dart';
import 'announcement_screen.dart';
import 'content_screen.dart';
import 'quiz_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final UserService _userService = UserService();
  String _totalStudents = '...';

  @override
  void initState() {
    super.initState();
    _fetchStudentCount();
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

  static const List<BoxShadow> _cardShadow = [
    BoxShadow(color: Color(0x0D000000), blurRadius: 10, offset: Offset(0, 2)),
  ];

  @override
  Widget build(BuildContext context) {
    final quickActions = [
      {
        'icon': Icons.people_rounded,
        'label': 'Students',
        'builder': (BuildContext c) => const StudentsScreen(),
      },
      {
        'icon': Icons.campaign_rounded,
        'label': 'Announcements',
        'builder': (BuildContext c) => const AnnouncementsScreen(),
      },
      {
        'icon': Icons.folder_rounded,
        'label': 'Content',
        'builder': (BuildContext c) => const ContentScreen(),
      },
      {
        'icon': Icons.quiz_rounded,
        'label': 'Quiz',
        'builder': (BuildContext c) => const QuizScreen(),
      },
    ];

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
      backgroundColor: const Color(0xFFF7F7F7),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildTopBar(),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildStudentCountCard(),
                    const SizedBox(height: 20),
                    const Text(
                      'Quick Actions',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 10),
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            crossAxisSpacing: 12,
                            mainAxisSpacing: 12,
                            childAspectRatio: 2.1,
                          ),
                      itemCount: quickActions.length,
                      itemBuilder: (context, index) {
                        final action = quickActions[index];
                        return _buildQuickActionCard(
                          icon: action['icon'] as IconData,
                          label: action['label'] as String,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: action['builder'] as WidgetBuilder,
                              ),
                            );
                          },
                        );
                      },
                    ),
                    const SizedBox(height: 20),
                    _buildRecentActivityCard(recentActivity),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 26),
      decoration: const BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(28),
          bottomRight: Radius.circular(28),
        ),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Dashboard Overview',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
          SizedBox(height: 4),
          Text(
            "Welcome back! Here's what's happening today.",
            style: TextStyle(fontSize: 13, color: Color(0xFFB3B3B3)),
          ),
        ],
      ),
    );
  }

  Widget _buildStudentCountCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: _cardShadow,
        border: Border.all(color: const Color(0xFFF0F0F0)),
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: Colors.black,
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.people_rounded,
              color: Colors.white,
              size: 26,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Total Students',
                  style: TextStyle(fontSize: 13, color: Colors.black54),
                ),
                const SizedBox(height: 2),
                Text(
                  _totalStudents,
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    color: Colors.black,
                  ),
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

  Widget _buildQuickActionCard({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: _cardShadow,
          border: Border.all(color: const Color(0xFFF0F0F0)),
        ),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.06),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: Colors.black, size: 19),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: Colors.black,
                ),
              ),
            ),
            const Icon(
              Icons.chevron_right_rounded,
              color: Colors.black26,
              size: 18,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentActivityCard(List<Map<String, String>> recentActivity) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: _cardShadow,
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
