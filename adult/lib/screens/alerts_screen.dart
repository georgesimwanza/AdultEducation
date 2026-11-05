import 'package:flutter/material.dart';

import 'package:adult/Model/lms_models.dart';
import 'package:adult/screens/color.dart';
import 'package:adult/screens/lms_widgets.dart';
import 'package:adult/service/lms_api.dart';

/// Server notifications: deadlines, grades, announcements, messages and
/// completed courses.
class AlertsScreen extends StatefulWidget {
  const AlertsScreen({super.key});

  @override
  State<AlertsScreen> createState() => _AlertsScreenState();
}

class _AlertsScreenState extends State<AlertsScreen> {
  final key = GlobalKey<AsyncViewState<List<AppNotification>>>();

  static (IconData, Color) _style(String type) => switch (type) {
        'DEADLINE' => (Icons.alarm_rounded, EduColors.accent),
        'GRADE' => (Icons.grade_rounded, EduColors.success),
        'ANNOUNCEMENT' => (Icons.campaign_rounded, EduColors.primary),
        'MESSAGE' => (Icons.chat_bubble_rounded, EduColors.primary),
        'COURSE' => (Icons.emoji_events_rounded, EduColors.success),
        _ => (Icons.notifications_rounded, EduColors.textSecondary),
      };

  @override
  Widget build(BuildContext context) {
    return LmsPage(
      title: 'Alerts',
      actions: [
        TextButton.icon(
          onPressed: () async {
            try {
              await LmsApi.put('/notifications/read-all');
              key.currentState?.reload();
            } catch (e) {
              if (context.mounted) showError(context, e);
            }
          },
          icon: const Icon(Icons.done_all_rounded),
          label: const Text('Mark all read'),
        ),
      ],
      body: AsyncView<List<AppNotification>>(
        key: key,
        load: () async =>
            ((await LmsApi.get('/notifications')) as List).map((e) => AppNotification.fromJson(e)).toList(),
        builder: (context, list, reload) {
          if (list.isEmpty) {
            return const EmptyState(
              icon: Icons.notifications_none_rounded,
              title: 'No alerts',
              message: 'Deadlines, grades and announcements will show here.',
            );
          }
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              for (final n in list)
                LmsCard(
                  onTap: n.isUnread
                      ? () async {
                          try {
                            await LmsApi.put('/notifications/${n.id}/read');
                            reload();
                          } catch (_) {}
                        }
                      : null,
                  child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    CircleAvatar(
                      backgroundColor: _style(n.type).$2.withValues(alpha: 0.12),
                      child: Icon(_style(n.type).$1, color: _style(n.type).$2),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(n.title,
                            style: TextStyle(
                                fontSize: 15.5, fontWeight: n.isUnread ? FontWeight.w900 : FontWeight.w600)),
                        if (n.body != null && n.body!.isNotEmpty) ...[
                          const SizedBox(height: 3),
                          Text(n.body!, style: const TextStyle(color: EduColors.textSecondary)),
                        ],
                        const SizedBox(height: 4),
                        Text(relativeTime(n.createdAt),
                            style: const TextStyle(fontSize: 12, color: EduColors.textSecondary)),
                      ]),
                    ),
                    if (n.isUnread)
                      const Padding(
                        padding: EdgeInsets.only(top: 6),
                        child: CircleAvatar(radius: 5, backgroundColor: EduColors.danger),
                      ),
                  ]),
                ),
            ],
          );
        },
      ),
    );
  }
}
