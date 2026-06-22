import 'package:flutter/material.dart';

class NoticeBoardScreen extends StatefulWidget {
  const NoticeBoardScreen({super.key});

  @override
  State<NoticeBoardScreen> createState() => _NoticeBoardScreenState();
}

class _NoticeBoardScreenState extends State<NoticeBoardScreen> {
  final List<Notice> notices = [
    Notice(
      id: "1",
      title: "Urgent: CBC Assessment Guidelines Updated",
      content:
          "The Ministry has released the revised Competency-Based Curriculum tracking metrics for the upcoming term. Please download the attached offline module before Friday.",
      date: "June 22, 2026",
      isUrgent: true,
      isAcknowledged: false,
    ),
    Notice(
      id: "2",
      title: "System Architecture Seminar: Venue Change",
      content:
          "The seminar scheduled for tomorrow has been moved from Hall B to the Main Auditorium due to capacity constraints.",
      date: "June 20, 2026",
      isUrgent: false,
      isAcknowledged: false,
    ),
    Notice(
      id: "3",
      title: "Final Year Project Deadlines",
      content:
          "Draft proposals for the digital support system implementations are due next week. Ensure all offline repositories are synced.",
      date: "June 18, 2026",
      isUrgent: false,
      isAcknowledged: true,
    ),
  ];

  int get _unacknowledgedCount =>
      notices.where((n) => !n.isAcknowledged).length;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        titleSpacing: 0,
        leading: const BackButton(),
        title: Row(
          children: [
            CircleAvatar(
              radius: 17,
              backgroundColor: Colors.white24,
              child: const Icon(
                Icons.campaign_outlined,
                color: Colors.white,
                size: 18,
              ),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Notice Board',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                ),
                Text(
                  '$_unacknowledgedCount unread',
                  style: const TextStyle(fontSize: 11, color: Colors.white70),
                ),
              ],
            ),
          ],
        ),
        actions: const [Icon(Icons.tune_outlined), SizedBox(width: 16)],
      ),
      body: notices.isEmpty
          ? const Center(
              child: Text(
                'No notices yet.',
                style: TextStyle(color: Colors.grey, fontSize: 14),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              itemCount: notices.length + 1,
              itemBuilder: (context, index) {
                if (index == 0) return _buildDateDivider('Today');
                return _buildNoticeCard(notices[index - 1], index - 1);
              },
            ),
    );
  }

  Widget _buildDateDivider(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Center(
        child: Text(
          label,
          style: const TextStyle(fontSize: 11, color: Colors.grey),
        ),
      ),
    );
  }

  Widget _buildNoticeCard(Notice notice, int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Left accent — black for urgent, light grey for normal
              Container(
                width: 4,
                color: notice.isUrgent ? Colors.black : Colors.grey.shade200,
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Date row + urgent badge
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              const Icon(
                                Icons.calendar_today_outlined,
                                size: 11,
                                color: Colors.grey,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                notice.date,
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                          if (notice.isUrgent)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.black,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Text(
                                'URGENT',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 9,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.6,
                                ),
                              ),
                            )
                          else if (notice.isAcknowledged)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.grey.shade100,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                'READ',
                                style: TextStyle(
                                  color: Colors.grey.shade500,
                                  fontSize: 9,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.6,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 10),

                      // Title
                      Text(
                        notice.title,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          height: 1.35,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 6),

                      // Body
                      Text(
                        notice.content,
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade600,
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 14),

                      // Divider + action row
                      Divider(color: Colors.grey.shade100, thickness: 1),
                      const SizedBox(height: 6),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // Posted by chip
                          Row(
                            children: [
                              CircleAvatar(
                                radius: 11,
                                backgroundColor: Colors.grey.shade100,
                                child: const Icon(
                                  Icons.person_outline,
                                  size: 13,
                                  color: Colors.grey,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'Admin',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey.shade500,
                                ),
                              ),
                            ],
                          ),
                          _buildAcknowledgeButton(notice, index),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAcknowledgeButton(Notice notice, int index) {
    return GestureDetector(
      onTap: () => setState(
        () => notices[index].isAcknowledged = !notices[index].isAcknowledged,
      ),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: notice.isAcknowledged ? Colors.white : Colors.black,
          border: Border.all(
            color: notice.isAcknowledged ? Colors.grey.shade300 : Colors.black,
          ),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              notice.isAcknowledged
                  ? Icons.check_circle
                  : Icons.circle_outlined,
              size: 14,
              color: notice.isAcknowledged
                  ? Colors.grey.shade500
                  : Colors.white,
            ),
            const SizedBox(width: 6),
            Text(
              notice.isAcknowledged ? 'Acknowledged' : 'Acknowledge',
              style: TextStyle(
                color: notice.isAcknowledged
                    ? Colors.grey.shade500
                    : Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// DATA MODEL
class Notice {
  final String id;
  final String title;
  final String content;
  final String date;
  final bool isUrgent;
  bool isAcknowledged;

  Notice({
    required this.id,
    required this.title,
    required this.content,
    required this.date,
    required this.isUrgent,
    this.isAcknowledged = false,
  });
}
