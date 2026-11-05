import 'package:flutter/foundation.dart';

import 'package:adult/model/schedule_model.dart';
import 'package:adult/service/notifications/platform_notifications.dart' as platform;

/// Something new that a sync found (a file, announcement or quiz).
class NewItem {
  final String action;
  final String name;
  const NewItem(this.action, this.name);
}

/// System notifications: new content after a sync and reminders before
/// study sessions.
///
/// On Android they are real system notifications. Study reminders are
/// scheduled on the phone, so they fire offline and with the app closed, and
/// a background check syncs every ~15 minutes when there is a connection.
/// On the web they are browser notifications, shown while the app is open.
class NotificationService {
  NotificationService._();

  /// How long before a study session its reminder fires.
  static const reminderLead = Duration(minutes: 15);

  /// Study sessions further ahead than this get their reminder on a later
  /// reschedule (Android limits how many alarms an app can hold).
  static const _reminderWindow = Duration(days: 30);

  static bool _ready = false;

  static Future<void> init() async {
    if (_ready) return;
    try {
      await platform.initNotifications();
      _ready = true;
    } catch (e) {
      debugPrint('Notifications unavailable: $e');
    }
  }

  /// Starts the background check for new content (Android only).
  static Future<void> startBackgroundSync() async {
    try {
      await platform.startBackgroundSync();
    } catch (e) {
      debugPrint('Background sync not started: $e');
    }
  }

  /// Tells the user what a sync found. Nothing new, no notification.
  static Future<void> notifyNewItems(List<NewItem> items) async {
    if (items.isEmpty) return;
    await init();
    if (!_ready) return;
    final String title, body;
    if (items.length == 1) {
      title = items.first.action;
      body = items.first.name;
    } else {
      title = '${items.length} new updates';
      body = items.map((i) => '${i.action}: ${i.name}').join('\n');
    }
    try {
      await platform.showNow(title, body);
    } catch (e) {
      debugPrint('Could not show notification: $e');
    }
  }

  /// Replaces all study reminders with ones for [entries].
  static Future<void> rescheduleStudyReminders(List<ScheduleEntry> entries) async {
    await init();
    if (!_ready) return;
    final now = DateTime.now();
    final reminders = <platform.Reminder>[];
    for (final e in entries) {
      final start = sessionStart(e);
      if (start == null || !start.isAfter(now) || start.difference(now) > _reminderWindow) {
        continue;
      }
      // Session starts within the lead time: remind right away instead.
      var at = start.subtract(reminderLead);
      if (!at.isAfter(now)) at = now.add(const Duration(seconds: 5));
      final minutes = start.difference(at).inMinutes;
      reminders.add(platform.Reminder(
        at: at,
        title: 'Study session: ${e.title}',
        body: minutes >= 1
            ? 'Starts in $minutes minutes (${_hhmm(e.startTime)} – ${_hhmm(e.endTime)})'
            : 'Starting now (${_hhmm(e.startTime)} – ${_hhmm(e.endTime)})',
      ));
    }
    reminders.sort((a, b) => a.at.compareTo(b.at));
    try {
      await platform.scheduleReminders(reminders);
    } catch (e) {
      debugPrint('Could not schedule study reminders: $e');
    }
  }

  /// When a session starts, from its date and "HH:mm" (or "HH:mm:ss") time.
  static DateTime? sessionStart(ScheduleEntry e) {
    final parts = e.startTime.split(':');
    if (parts.length < 2) return null;
    final h = int.tryParse(parts[0]), m = int.tryParse(parts[1]);
    if (h == null || m == null) return null;
    return DateTime(e.date.year, e.date.month, e.date.day, h, m);
  }

  static String _hhmm(String t) => t.length >= 5 ? t.substring(0, 5) : t;
}
