import 'package:sqflite/sqflite.dart';

/// Icon keys match _activityIcons in DashboardScreen: 'person', 'document',
/// 'gear', 'shield'. Pick whichever fits, or add a new key to both places.
class ActivityLogEntry {
  final String action;
  final String name;
  final String icon;
  final DateTime timestamp;

  ActivityLogEntry({
    required this.action,
    required this.name,
    required this.icon,
    required this.timestamp,
  });
}

/// Purely local activity feed — nothing here ever touches the network.
/// Call log() right after any action you want to show up on the dashboard
/// (adding a student, uploading content, updating a subject, adding an
/// admin, ...). Wire it in wherever those actions currently succeed.
class ActivityLogService {
  final Database db;

  ActivityLogService({required this.db});

  Future<void> log({
    required String action,
    required String name,
    required String icon,
  }) async {
    await db.insert('activity_log', {
      'action': action,
      'name': name,
      'icon': icon,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    });
  }

  Future<List<ActivityLogEntry>> recent({int limit = 10}) async {
    final rows = await db.query(
      'activity_log',
      orderBy: 'timestamp DESC',
      limit: limit,
    );
    return rows
        .map(
          (r) => ActivityLogEntry(
            action: r['action'] as String,
            name: r['name'] as String,
            icon: r['icon'] as String,
            timestamp: DateTime.fromMillisecondsSinceEpoch(
              r['timestamp'] as int,
            ),
          ),
        )
        .toList();
  }
}
