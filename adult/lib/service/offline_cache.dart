import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common/sqlite_api.dart';

/// Thrown when there is no connection: the change was saved on the device
/// and will be sent to the server automatically after reconnecting.
class QueuedOffline implements Exception {
  const QueuedOffline();

  @override
  String toString() => 'Saved on this device. It will be sent when you are back online.';
}

/// Keeps a copy of every server answer the app has read, so screens still
/// show their data offline, and an outbox of changes made while offline.
///
/// Both live in the same local database SyncService opens (IndexedDB on
/// the web), so they survive closing the browser.
class OfflineCache {
  OfflineCache._();

  static Database? _db;

  /// Set by main from ConnectivityService: while offline, reads come
  /// straight from the cache instead of waiting for a request to time out.
  static bool Function() isOffline = () => false;

  /// Set by main: called when the server says the login token is no longer
  /// valid (it lasts 24 hours), to send the user back to the login screen.
  static void Function()? onUnauthorized;

  static const createSql = [
    '''
    CREATE TABLE IF NOT EXISTS api_cache (
      url TEXT PRIMARY KEY,
      body TEXT,
      contentType TEXT,
      updatedAt INTEGER
    )
    ''',
    // Each change keeps the token it was made with, so it is sent as the
    // person who made it even if someone else signs in before reconnecting.
    '''
    CREATE TABLE IF NOT EXISTS api_outbox (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      method TEXT,
      url TEXT,
      body TEXT,
      headers TEXT,
      createdAt INTEGER
    )
    ''',
  ];

  static Future<void> attach(Database db) async {
    for (final sql in createSql) {
      await db.execute(sql);
    }
    _db = db;
  }

  // ── Cache ──

  static Future<void> save(String url, http.Response res) async {
    final db = _db;
    if (db == null) return;
    try {
      await db.insert('api_cache', {
        'url': url,
        'body': base64Encode(res.bodyBytes),
        'contentType': res.headers['content-type'],
        'updatedAt': DateTime.now().millisecondsSinceEpoch,
      }, conflictAlgorithm: ConflictAlgorithm.replace);
    } catch (e) {
      debugPrint('Could not cache $url: $e');
    }
  }

  /// The last answer saved for [url], or null if it was never loaded.
  static Future<http.Response?> load(String url) async {
    final db = _db;
    if (db == null) return null;
    final rows = await db.query('api_cache', where: 'url = ?', whereArgs: [url]);
    if (rows.isEmpty) return null;
    final contentType = rows.first['contentType'] as String?;
    return http.Response.bytes(
      base64Decode(rows.first['body'] as String),
      200,
      headers: {if (contentType != null) 'content-type': contentType},
    );
  }

  /// Adds [item] to a cached JSON list, so something done offline (e.g. a
  /// message sent) shows up in the list right away.
  static Future<void> appendToList(String url, Map<String, dynamic> item) async {
    final cached = await load(url);
    final list = cached == null ? <dynamic>[] : jsonDecode(cached.body) as List;
    await save(
      url,
      http.Response.bytes(utf8.encode(jsonEncode([...list, item])), 200,
          headers: {'content-type': 'application/json; charset=utf-8'}),
    );
  }

  /// Removes everything cached (e.g. on sign-out, so the next person on
  /// this device doesn't see it). Pending changes are kept.
  static Future<void> clear() async {
    await _db?.delete('api_cache');
  }

  // ── Outbox ──

  static Future<void> enqueue(
    String method,
    String url,
    String? body,
    Map<String, String> headers,
  ) async {
    final db = _db;
    if (db == null) throw StateError('Local storage is not ready');
    await db.insert('api_outbox', {
      'method': method,
      'url': url,
      'body': body,
      'headers': jsonEncode(headers),
      'createdAt': DateTime.now().millisecondsSinceEpoch,
    });
  }

  static Future<int> pendingCount() async {
    final db = _db;
    if (db == null) return 0;
    final rows = await db.rawQuery('SELECT COUNT(*) AS n FROM api_outbox');
    return (rows.first['n'] as int?) ?? 0;
  }

  /// Sends the saved changes in the order they were made. Returns how many
  /// were sent. Stops at the first one that can't reach the server; a change
  /// the server refuses is dropped, since retrying it would never succeed.
  static Future<int> flush() async {
    final db = _db;
    if (db == null) return 0;
    final rows = await db.query('api_outbox', orderBy: 'id');
    final current = (await SharedPreferences.getInstance()).getString('auth_token');
    var sent = 0;
    for (final row in rows) {
      final uri = Uri.parse(row['url'] as String);
      final headers = Map<String, String>.from(jsonDecode(row['headers'] as String));
      // The saved token may have run out since; if the same person has
      // signed in again, send it with their new one.
      final saved = headers['Authorization']?.replaceFirst('Bearer ', '');
      if (current != null && saved != null && _subject(saved) != null &&
          _subject(saved) == _subject(current)) {
        headers['Authorization'] = 'Bearer $current';
      }
      final body = row['body'] as String?;
      final http.Response res;
      try {
        res = await switch (row['method']) {
          'POST' => http.post(uri, headers: headers, body: body),
          'PUT' => http.put(uri, headers: headers, body: body),
          'PATCH' => http.patch(uri, headers: headers, body: body),
          _ => http.delete(uri, headers: headers),
        }.timeout(const Duration(seconds: 20));
      } catch (_) {
        break;
      }
      // Token no longer valid: keep the change for after signing in again.
      if (res.statusCode == 401) break;
      if (res.statusCode >= 300) {
        debugPrint('Offline change refused (${res.statusCode}): ${row['method']} $uri ${res.body}');
      } else {
        sent++;
      }
      await db.delete('api_outbox', where: 'id = ?', whereArgs: [row['id']]);
    }
    return sent;
  }
}

/// Email (subject) inside a login token.
String? _subject(String token) {
  final parts = token.split('.');
  if (parts.length != 3) return null;
  try {
    final claims = jsonDecode(utf8.decode(base64Url.decode(base64Url.normalize(parts[1]))));
    return claims is Map ? claims['sub'] as String? : null;
  } catch (_) {
    return null;
  }
}

/// GET that falls back to the saved copy when the server can't be reached.
/// Successful answers are saved for next time. Throws if there is neither a
/// connection nor a saved copy.
Future<http.Response> cachedGet(
  Uri uri, {
  Map<String, String>? headers,
  Duration timeout = const Duration(seconds: 20),
}) async {
  final url = uri.toString();
  if (!OfflineCache.isOffline()) {
    try {
      final res = await http.get(uri, headers: headers).timeout(timeout);
      if (res.statusCode >= 200 && res.statusCode < 300) {
        await OfflineCache.save(url, res);
      } else if (res.statusCode == 401 && headers?['Authorization'] != null) {
        OfflineCache.onUnauthorized?.call();
      }
      return res;
    } catch (_) {
      // Fall through to the saved copy.
    }
  }
  final cached = await OfflineCache.load(url);
  if (cached != null) return cached;
  throw const NotSavedOffline();
}

class NotSavedOffline implements Exception {
  const NotSavedOffline();

  @override
  String toString() =>
      "You're offline and this page hasn't been saved on this device yet. "
      'Connect once and it will be available offline.';
}
