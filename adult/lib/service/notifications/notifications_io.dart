import 'dart:io' show Platform;

import 'package:flutter/widgets.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:workmanager/workmanager.dart';

import 'package:adult/Controller/auth_controller.dart';
import 'package:adult/service/notifications/reminder.dart';
import 'package:adult/service/sync_service.dart';

export 'package:adult/service/notifications/reminder.dart';

// System notifications through flutter_local_notifications, and a
// WorkManager job that syncs in the background (Android).

final _plugin = FlutterLocalNotificationsPlugin();

const _updatesChannel = AndroidNotificationDetails(
  'updates',
  'New content',
  channelDescription: 'New files, announcements and quizzes',
  importance: Importance.high,
  priority: Priority.high,
  styleInformation: BigTextStyleInformation(''),
);

const _remindersChannel = AndroidNotificationDetails(
  'study_reminders',
  'Study reminders',
  channelDescription: 'Reminders before your study sessions',
  importance: Importance.high,
  priority: Priority.high,
);

/// Study reminders use ids from here up, so rescheduling can cancel just
/// them and leave other notifications alone.
const _firstReminderId = 100000;

const _syncTask = 'pamodzi-background-sync';

Future<void> initNotifications() async {
  await _plugin.initialize(
    settings: const InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
    ),
  );
  if (Platform.isAndroid) {
    // Asks on Android 13+; earlier versions allow notifications by default.
    await _plugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
  }
}

Future<void> showNow(String title, String body) async {
  // Unique enough, and always below the reminder range.
  final id = DateTime.now().millisecondsSinceEpoch % _firstReminderId;
  await _plugin.show(
    id: id,
    title: title,
    body: body,
    notificationDetails: NotificationDetails(
      android: AndroidNotificationDetails(
        _updatesChannel.channelId,
        _updatesChannel.channelName,
        channelDescription: _updatesChannel.channelDescription,
        importance: _updatesChannel.importance,
        priority: _updatesChannel.priority,
        styleInformation: BigTextStyleInformation(body),
      ),
    ),
  );
}

Future<void> scheduleReminders(List<Reminder> reminders) async {
  for (final p in await _plugin.pendingNotificationRequests()) {
    if (p.id >= _firstReminderId) await _plugin.cancel(id: p.id);
  }
  final android = _plugin
      .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
  // Exact alarms need the user's permission on Android 14+; without it the
  // reminder may come a few minutes late.
  final exact = await android?.canScheduleExactNotifications() ?? false;
  var id = _firstReminderId;
  for (final r in reminders.take(60)) {
    await _plugin.zonedSchedule(
      id: id++,
      title: r.title,
      body: r.body,
      scheduledDate: tz.TZDateTime.from(r.at, tz.UTC),
      notificationDetails: const NotificationDetails(android: _remindersChannel),
      androidScheduleMode: exact
          ? AndroidScheduleMode.exactAllowWhileIdle
          : AndroidScheduleMode.inexactAllowWhileIdle,
    );
  }
}

Future<void> startBackgroundSync() async {
  if (!Platform.isAndroid) return;
  await Workmanager().initialize(backgroundSyncDispatcher);
  // Runs about every 15 minutes, only when there is a connection, so it also
  // catches up as soon as the phone is back online.
  await Workmanager().registerPeriodicTask(
    _syncTask,
    _syncTask,
    frequency: const Duration(minutes: 15),
    constraints: Constraints(networkType: NetworkType.connected),
    existingWorkPolicy: ExistingPeriodicWorkPolicy.keep,
  );
}

/// Runs in a background isolate started by Android's WorkManager.
@pragma('vm:entry-point')
void backgroundSyncDispatcher() {
  Workmanager().executeTask((task, _) async {
    WidgetsFlutterBinding.ensureInitialized();
    try {
      final auth = AuthController();
      await auth.init();
      if (auth.token == null || auth.tokenExpired) return true;
      final prefs = await SharedPreferences.getInstance();
      // Don't notify about the same things twice if the app synced moments ago.
      final last = prefs.getInt('last_sync_timestamp') ?? 0;
      if (DateTime.now().millisecondsSinceEpoch - last < const Duration(minutes: 10).inMilliseconds) {
        return true;
      }
      // Notifies about anything new, like a sync in the app does.
      await SyncService(authController: auth).syncOnStartup(prefetchPages: false);
      return true;
    } catch (e) {
      debugPrint('Background sync failed: $e');
      return false; // WorkManager retries later
    }
  });
}
