import 'package:flutter/material.dart';
import 'package:adult/Service/user_service.dart';

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
      final count = await _userService. countStudentsByInstitution();
      setState(() {
        _totalStudents = count.toString();
      });
    } catch (e) {
      setState(() {
        _totalStudents = 'N/A';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final stats = [
      {
        'label': 'Total Students',
        'value': _totalStudents, // 👈 real count
        'icon': Icons.people_rounded,
        'color': const Color.fromARGB(255, 0, 0, 0),
      },
      {
        'label': 'Active Admins',
        'value': '12',
        'icon': Icons.admin_panel_settings_rounded,
        'color': const Color.fromARGB(255, 0, 0, 0),
      },
      {
        'label': 'Content Items',
        'value': '456',
        'icon': Icons.book_rounded,
        'color': const Color.fromARGB(255, 0, 0, 0),
      },
      {
        'label': 'Subjects',
        'value': '24',
        'icon': Icons.school_rounded,
        'color': const Color.fromARGB(255, 0, 0, 0),
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
      backgroundColor: const Color.fromARGB(255, 255, 255, 255),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 8),
              const Text(
                'Dashboard Overview',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF111827),
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                "Welcome back! Here's what's happening today.",
                style: TextStyle(
                  fontSize: 14,
                  color: Color.fromARGB(255, 0, 0, 0),
                ),
              ),
              const SizedBox(height: 20),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 1.4,
                ),
                itemCount: stats.length,
                itemBuilder: (context, index) {
                  final stat = stats[index];
                  return Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 2),
                        ),
                      ],
                      border: Border.all(color: const Color(0xFFF3F4F6)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: stat['color'] as Color,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            stat['icon'] as IconData,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          stat['label'] as String,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color.fromARGB(255, 5, 8, 13),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          stat['value'] as String,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF111827),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                  border: Border.all(color: const Color(0xFFF3F4F6)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(
                          Icons.bolt_rounded,
                          color: Color.fromARGB(255, 0, 0, 0),
                          size: 20,
                        ),
                        SizedBox(width: 8),
                        Text(
                          'Recent Activity',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF111827),
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
                                    color: Color.fromARGB(255, 0, 0, 0),
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
                                        color: Color(0xFF111827),
                                      ),
                                    ),
                                    Text(
                                      activity['name']!,
                                      style: const TextStyle(
                                        fontSize: 13,
                                        color: Color.fromARGB(255, 0, 0, 0),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Text(
                                activity['time']!,
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: Color.fromARGB(255, 0, 0, 0),
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
              ),
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color.fromARGB(255, 10, 14, 22),
                      Color.fromARGB(255, 20, 31, 54),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.trending_up_rounded,
                      color: Colors.white,
                      size: 32,
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'System Performance',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Student engagement is up 23% this week!',
                      style: TextStyle(fontSize: 13, color: Color(0xFFBFDBFE)),
                    ),
                    const SizedBox(height: 16),
                    const Row(
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Completion Rate',
                              style: TextStyle(
                                fontSize: 11,
                                color: Color(0xFFBFDBFE),
                              ),
                            ),
                            SizedBox(height: 2),
                            Text(
                              '87%',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(width: 32),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Avg. Score',
                              style: TextStyle(
                                fontSize: 11,
                                color: Color(0xFFBFDBFE),
                              ),
                            ),
                            SizedBox(height: 2),
                            Text(
                              '82%',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}
