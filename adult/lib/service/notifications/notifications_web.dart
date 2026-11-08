import 'dart:async';
import 'dart:js_interop';

import 'package:web/web.dart' as web;

import 'package:adult/service/notifications/reminder.dart';

export 'package:adult/service/notifications/reminder.dart';

// Browser notifications. A page can only show them while it is open, so
// study reminders here are timers that fire while the app's tab is open.

final List<Timer> _timers = [];

Future<void> initNotifications({void Function(String? payload)? onTap}) async {
  if (web.Notification.permission == 'default') {
    await web.Notification.requestPermission().toDart;
  }
}

Future<void> showNow(String title, String body) async {
  if (web.Notification.permission != 'granted') return;
  web.Notification(
    title,
    web.NotificationOptions(body: body, icon: 'icons/Icon-192.png'),
  );
}

/// The web syncs on its own when the connection returns, so it never asks.
Future<void> showSyncPrompt(String title, String body) async {}

Future<void> clearSyncPrompt() async {}

Future<void> scheduleReminders(List<Reminder> reminders) async {
  for (final t in _timers) {
    t.cancel();
  }
  _timers.clear();
  final now = DateTime.now();
  for (final r in reminders) {
    _timers.add(Timer(r.at.difference(now), () => showNow(r.title, r.body)));
  }
}

/// Browsers don't run the app in the background.
Future<void> startBackgroundSync() async {}
