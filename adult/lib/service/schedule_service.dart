import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:sqflite/sqflite.dart';
import '../model/schedule_model.dart';
import 'package:adult/service/api_config.dart';

class ScheduleService {
  static const String _base = '$kBackendHost/api';
  final Database db;

  ScheduleService({required this.db});

  // ---------- CREATE ----------
  Future<ScheduleEntry> createSchedule(ScheduleEntry entry) async {
    try {
      final response = await http
          .post(
            Uri.parse('$_base/schedules'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(entry.toJson()),
          )
          .timeout(const Duration(seconds: 8));

      if (response.statusCode == 200 || response.statusCode == 201) {
        final saved = ScheduleEntry.fromJson(jsonDecode(response.body));
        await _upsertLocal(saved, synced: true);
        return saved;
      }
      throw Exception('Failed to save schedule: ${response.statusCode}');
    } catch (e) {
      // Offline / server unreachable — keep it locally, sync later.
      final localId =
          entry.toJson()['id'] ??
          'local_${DateTime.now().millisecondsSinceEpoch}';
      final localJson = {...entry.toJson(), 'id': localId};
      final localEntry = ScheduleEntry.fromJson(localJson);
      await _upsertLocal(localEntry, synced: false);
      return localEntry;
    }
  }

  // ---------- READ ----------
  Future<List<ScheduleEntry>> fetchSchedules(String email) async {
    // Push anything pending first so a successful fetch reflects it.
    await syncPendingChanges();

    try {
      final response = await http
          .get(
            Uri.parse('$_base/schedules?email=${Uri.encodeComponent(email)}'),
            headers: {'Content-Type': 'application/json'},
          )
          .timeout(const Duration(seconds: 8));

      if (response.statusCode == 200) {
        final List data = jsonDecode(response.body);
        final entries = data.map((e) => ScheduleEntry.fromJson(e)).toList();
        for (final entry in entries) {
          await _upsertLocal(entry, synced: true);
        }
        return entries;
      }
      throw Exception('Failed to fetch schedules: ${response.statusCode}');
    } catch (e) {
      // Offline — fall back to whatever's cached locally.
      return _readLocal(email);
    }
  }

  // ---------- DELETE ----------
  Future<void> deleteSchedule(String id) async {
    final isLocalOnly = id.startsWith('local_');
    if (!isLocalOnly) {
      try {
        final response = await http
            .delete(Uri.parse('$_base/schedules/$id'))
            .timeout(const Duration(seconds: 8));
        if (response.statusCode == 200 || response.statusCode == 204) {
          await db.delete('schedules', where: 'id = ?', whereArgs: [id]);
          return;
        }
        throw Exception('Failed to delete schedule: ${response.statusCode}');
      } catch (e) {
        // Offline — mark for deletion, remove properly once back online.
        await db.update(
          'schedules',
          {'pendingDelete': 1},
          where: 'id = ?',
          whereArgs: [id],
        );
        return;
      }
    }
    // Never made it to the server — just drop it locally.
    await db.delete('schedules', where: 'id = ?', whereArgs: [id]);
  }

  // ---------- SYNC ----------
  Future<void> syncPendingChanges() async {
    // Push pending deletes.
    final toDelete = await db.query('schedules', where: 'pendingDelete = 1');
    for (final row in toDelete) {
      final id = row['id'] as String;
      if (id.startsWith('local_')) {
        await db.delete('schedules', where: 'id = ?', whereArgs: [id]);
        continue;
      }
      try {
        final response = await http
            .delete(Uri.parse('$_base/schedules/$id'))
            .timeout(const Duration(seconds: 8));
        if (response.statusCode == 200 || response.statusCode == 204) {
          await db.delete('schedules', where: 'id = ?', whereArgs: [id]);
        }
      } catch (_) {
        // still offline, try again next time
      }
    }

    // Push unsynced creates/updates.
    final unsynced = await db.query(
      'schedules',
      where: 'synced = 0 AND pendingDelete = 0',
    );
    for (final row in unsynced) {
      final entry = ScheduleEntry.fromJson(jsonDecode(row['data'] as String));
      try {
        final response = await http
            .post(
              Uri.parse('$_base/schedules'),
              headers: {'Content-Type': 'application/json'},
              body: jsonEncode(entry.toJson()),
            )
            .timeout(const Duration(seconds: 8));

        if (response.statusCode == 200 || response.statusCode == 201) {
          final saved = ScheduleEntry.fromJson(jsonDecode(response.body));
          await db.delete('schedules', where: 'id = ?', whereArgs: [row['id']]);
          await _upsertLocal(saved, synced: true);
        }
      } catch (_) {
        // still offline, try again next time
      }
    }
  }

  // ---------- local helpers ----------
  Future<void> _upsertLocal(ScheduleEntry entry, {required bool synced}) async {
    final json = entry.toJson();
    await db.insert('schedules', {
      'id': json['id'],
      'email': json['email'],
      'data': jsonEncode(json),
      'synced': synced ? 1 : 0,
      'pendingDelete': 0,
      'updatedAt': DateTime.now().millisecondsSinceEpoch,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<ScheduleEntry>> _readLocal(String email) async {
    final rows = await db.query(
      'schedules',
      where: 'email = ? AND pendingDelete = 0',
      whereArgs: [email],
    );
    return rows
        .map((r) => ScheduleEntry.fromJson(jsonDecode(r['data'] as String)))
        .toList();
  }
}
