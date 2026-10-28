import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path/path.dart';
import 'package:adult/Controller/auth_controller.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:adult/service/user_profile_service.dart';
import 'package:adult/service/api_config.dart';

class SyncService {
  final AuthController authController;
  final Dio dio = Dio();
  Database? db;

  static const String _baseUrl = '$kBackendHost';

  SyncService({required this.authController});

  Future<void> initDb() async {
    print('🗄️ Initializing database...');
    // Browsers have no native sqlite; use the WASM-backed factory instead.
    if (kIsWeb) databaseFactory = databaseFactoryFfiWebNoWebWorker;
    // The web factory has no databases directory; the name alone is enough.
    final dbPath = kIsWeb ? '' : await getDatabasesPath();
    db = await openDatabase(
      kIsWeb ? 'app.db' : join(dbPath, 'app.db'),
      version: 8, // ← bumped to 8 (added content.localPath)
      // Runs on every open (after create/upgrade), so user_profile exists on
      // fresh installs AND on databases created before it existed. It is never
      // dropped: it can hold edits that haven't been pushed to the server.
      onOpen: (db) async {
        await db.execute(UserProfileService.createSql);
      },
      onCreate: (db, version) async {
        print('🗄️ Creating tables...');
        await db.execute('''
          CREATE TABLE subjects (
            id INTEGER PRIMARY KEY,
            CourseCode TEXT,
            courseName TEXT,
            description TEXT,
            programmeId INTEGER
          )
        ''');
        await db.execute('''
          CREATE TABLE content (
            id INTEGER PRIMARY KEY,
            title TEXT,
            type TEXT,
            fileUrl TEXT,
            courseId INTEGER,
            institutionId INTEGER,
            localPath TEXT
          )
        ''');
        await db.execute('''
          CREATE TABLE programmes (
            id INTEGER PRIMARY KEY,
            name TEXT,
            code TEXT,
            description TEXT
          )
        ''');
        await db.execute('''
          CREATE TABLE schedules (
            id TEXT PRIMARY KEY,
            email TEXT,
            data TEXT,
            synced INTEGER DEFAULT 1,
            pendingDelete INTEGER DEFAULT 0,
            updatedAt INTEGER
          )
        ''');
        await _createAnnouncementQuizTables(db);
        print('✅ Tables created successfully');
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        print('🔄 Upgrading database from v$oldVersion to v$newVersion...');
        await db.execute('DROP TABLE IF EXISTS subjects');
        await db.execute('DROP TABLE IF EXISTS content');
        await db.execute('DROP TABLE IF EXISTS programmes');
        await db.execute('''
          CREATE TABLE subjects (
            id INTEGER PRIMARY KEY,
            CourseCode TEXT,
            courseName TEXT,
            description TEXT,
            programmeId INTEGER
          )
        ''');
        await db.execute('''
          CREATE TABLE content (
            id INTEGER PRIMARY KEY,
            title TEXT,
            type TEXT,
            fileUrl TEXT,
            courseId INTEGER,
            institutionId INTEGER,
            localPath TEXT
          )
        ''');
        await db.execute('''
          CREATE TABLE programmes (
            id INTEGER PRIMARY KEY,
            name TEXT,
            code TEXT,
            description TEXT
          )
        ''');
        // schedules and quiz_submissions are intentionally NOT dropped —
        // they can hold local writes that haven't synced to the server
        // yet, so a drop would silently lose user data on upgrade.
        await db.execute('''
          CREATE TABLE IF NOT EXISTS schedules (
            id TEXT PRIMARY KEY,
            email TEXT,
            data TEXT,
            synced INTEGER DEFAULT 1,
            pendingDelete INTEGER DEFAULT 0,
            updatedAt INTEGER
          )
        ''');
        // announcements and quizzes are pure server-owned caches, safe to
        // drop and recreate like subjects/content/programmes.
        await db.execute('DROP TABLE IF EXISTS announcements');
        await db.execute('DROP TABLE IF EXISTS quizzes');
        await _createAnnouncementQuizTables(db);
        print('✅ Database upgraded successfully');
      },
    );
    print('✅ Database initialized');
  }

  Future<void> _createAnnouncementQuizTables(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS announcements (
        id INTEGER PRIMARY KEY,
        institutionId INTEGER,
        programmeId INTEGER,
        title TEXT,
        content TEXT
      )
    ''');
    await db.execute('''
      CREATE TABLE IF NOT EXISTS quizzes (
        id INTEGER PRIMARY KEY,
        courseId INTEGER,
        institutionId INTEGER,
        programmeId INTEGER,
        data TEXT
      )
    ''');
    // quiz_submissions holds the student's own answers, so — like
    // schedules — it must never be dropped on upgrade.
    await db.execute('''
      CREATE TABLE IF NOT EXISTS quiz_submissions (
        id TEXT PRIMARY KEY,
        quizId INTEGER,
        email TEXT,
        answersJson TEXT,
        score INTEGER,
        synced INTEGER DEFAULT 0,
        submittedAt INTEGER
      )
    ''');
    // Dashboard's institution-name lookup was already querying this table —
    // it just never existed, which is why it always fell back to the
    // generic "Institution" placeholder.
    await db.execute('''
      CREATE TABLE IF NOT EXISTS institutions (
        id INTEGER PRIMARY KEY,
        name TEXT
      )
    ''');
    // Purely local activity feed — the app writes to this itself whenever
    // something happens (adding a student, uploading content, etc.). No
    // backend involved, and it's never dropped on upgrade since it's a
    // record of things that happened, not a server-owned cache.
    await db.execute('''
      CREATE TABLE IF NOT EXISTS activity_log (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        action TEXT,
        name TEXT,
        icon TEXT,
        timestamp INTEGER
      )
    ''');
  }

  Future<int?> getLastSyncTimestamp() async {
    final prefs = await SharedPreferences.getInstance();
    final timestamp = prefs.getInt('last_sync_timestamp');
    print('🕐 Last sync timestamp: $timestamp');
    return timestamp;
  }

  Future<void> saveLastSyncTimestamp() async {
    final prefs = await SharedPreferences.getInstance();
    final now = DateTime.now().millisecondsSinceEpoch;
    await prefs.setInt('last_sync_timestamp', now);
    print('💾 Saved new sync timestamp: $now');
  }

  /// [onProgress] is called with a short, user-facing status string at each
  /// major stage — e.g. for a loading screen to display live. Optional; if
  /// omitted, sync behaves exactly as before (debug prints only).
  Future<void> syncOnStartup({void Function(String stage)? onProgress}) async {
    print('🚀 Starting sync on startup...');
    onProgress?.call('Preparing local storage...');
    await initDb();

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('last_sync_timestamp');
    print('🧹 Cleared timestamp — forcing full download');

    final token = authController.token;
    if (token != null) {
      dio.options.headers['Authorization'] = 'Bearer $token';
      print('🔑 Token attached to sync requests');
    } else {
      print('⚠️ No token found — skipping sync');
      return;
    }

    final lastSync = await getLastSyncTimestamp();

    if (lastSync == null) {
      print('📥 No previous sync found — performing full download');
    } else {
      print('🔄 Previous sync found — fetching changes since $lastSync');
    }

    // Remember what we already had so we can tell what's new afterwards.
    final before = await _snapshotIds();

    onProgress?.call('Loading content locally...');
    await Future.wait([
      _syncSubjects(lastSync, onProgress),
      _syncContent(lastSync, onProgress),
      _syncProgrammes(lastSync, onProgress),
      _syncAnnouncements(lastSync, onProgress),
      _syncQuizzes(lastSync, onProgress),
      _syncUserProfile(onProgress),
    ]);

    await _recordNewItems(before);

    await downloadContentFiles(onProgress: onProgress);

    onProgress?.call('Finishing up...');
    await saveLastSyncTimestamp();
    print('✅ Sync completed successfully');
  }

  Future<void> _syncSubjects(
      int? since,
      void Function(String)? onProgress,
      ) async {
    try {
      print(
        '📚 Fetching subjects${since != null ? ' since $since' : ' (full)'}...',
      );
      final res = await dio.get(
        '$_baseUrl/api/sync/subjects',
        queryParameters: since != null ? {'since': since} : null,
      );

      final List data = res.data;
      print('📚 Received ${data.length} subjects from server');
      onProgress?.call('Loading subjects...');

      for (var item in data) {
        await db!.insert(
          'subjects',
          item,
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
        print('💾 Saved subject: ${item['courseName']}');
      }

      print('✅ Subjects sync done — ${data.length} records saved');
    } catch (e) {
      print('❌ Error syncing subjects: $e');
    }
  }

  Future<void> _syncContent(
      int? since,
      void Function(String)? onProgress,
      ) async {
    try {
      print(
        '📄 Fetching content${since != null ? ' since $since' : ' (full)'}...',
      );
      final res = await dio.get(
        '$_baseUrl/api/sync/content',
        queryParameters: since != null ? {'since': since} : null,
      );

      final List data = res.data;
      print('📄 Received ${data.length} content items from server');
      onProgress?.call('Loading course materials...');

      for (var item in data) {
        await db!.insert(
          'content',
          item,
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
        print('💾 Saved content: ${item['title']}');
      }

      print('✅ Content sync done — ${data.length} records saved');
    } catch (e) {
      print('❌ Error syncing content: $e');
    }
  }

  Future<void> _syncProgrammes(
      int? since,
      void Function(String)? onProgress,
      ) async {
    try {
      print(
        '🎓 Fetching programmes${since != null ? ' since $since' : ' (full)'}...',
      );
      final res = await dio.get(
        '$_baseUrl/api/sync/programmes',
        queryParameters: since != null ? {'since': since} : null,
      );

      final List data = res.data;
      print('🎓 Received ${data.length} programmes from server');
      onProgress?.call('Loading programmes...');

      for (var item in data) {
        await db!.insert(
          'programmes',
          item,
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
        print('💾 Saved programme: ${item['name']}');
      }

      print('✅ Programmes sync done — ${data.length} records saved');
    } catch (e) {
      print('❌ Error syncing programmes: $e');
    }
  }

  Future<void> _syncAnnouncements(
      int? since,
      void Function(String)? onProgress,
      ) async {
    try {
      print(
        '📢 Fetching announcements${since != null ? ' since $since' : ' (full)'}...',
      );
      final res = await dio.get(
        '$_baseUrl/api/sync/announcements',
        queryParameters: since != null ? {'since': since} : null,
      );

      final List data = res.data;
      print('📢 Received ${data.length} announcements from server');
      onProgress?.call('Loading announcements...');

      for (var item in data) {
        // /api/sync/announcements now returns AnnouncementDTO — flat
        // institutionId/programmeId, not nested institution/programme
        // objects (that switch is what fixed the Jackson recursion crash).
        await db!.insert('announcements', {
          'id': item['id'],
          'institutionId': item['institutionId'],
          'programmeId': item['programmeId'],
          'title': item['title'],
          'content': item['content'],
        }, conflictAlgorithm: ConflictAlgorithm.replace);
        print('💾 Saved announcement: ${item['title']}');
      }

      print('✅ Announcements sync done — ${data.length} records saved');
    } catch (e) {
      print('❌ Error syncing announcements: $e');
    }
  }

  Future<void> _syncQuizzes(
      int? since,
      void Function(String)? onProgress,
      ) async {
    try {
      print(
        '🧩 Fetching quizzes${since != null ? ' since $since' : ' (full)'}...',
      );
      final res = await dio.get(
        '$_baseUrl/api/sync/quizzes',
        queryParameters: since != null ? {'since': since} : null,
      );

      final List data = res.data;
      print('🧩 Received ${data.length} quizzes from server');
      onProgress?.call('Loading quizzes...');

      // /api/sync/quizzes returns QuizDto (String id, flat courseId /
      // institutionId / programmeId) — the same shape as /api/quizzes, so
      // Quiz.fromJson can read the stored JSON when offline.
      await db!.transaction((txn) async {
        // Full sync: drop quizzes deleted on the server so they don't linger.
        if (since == null) await txn.delete('quizzes');
        for (var item in data) {
          final id = int.tryParse('${item['id']}');
          if (id == null) continue;
          await txn.insert('quizzes', {
            'id': id,
            'courseId': item['courseId'],
            'institutionId': item['institutionId'],
            'programmeId': item['programmeId'],
            'data': jsonEncode(item),
          }, conflictAlgorithm: ConflictAlgorithm.replace);
          print('💾 Saved quiz: ${item['title']}');
        }
      });

      print('✅ Quizzes sync done — ${data.length} records saved');
    } catch (e) {
      print('❌ Error syncing quizzes: $e');
    }
  }

  // ── "What's new" notifications ──
  // After each sync, items that weren't on the device before are written to
  // the local activity_log table, which the dashboard shows as notifications.
  // (The server doesn't send created-at times for these, so the time shown is
  // when this device first saw the item.)

  /// More new items than this in one sync are summarised in a single entry.
  static const int _maxIndividualEvents = 3;

  Future<Map<String, Set<int>>> _snapshotIds() async {
    final out = <String, Set<int>>{};
    for (final table in const ['content', 'announcements', 'quizzes']) {
      try {
        final rows = await db!.query(table, columns: ['id']);
        out[table] = rows.map((r) => r['id']).whereType<int>().toSet();
      } catch (_) {
        out[table] = <int>{};
      }
    }
    return out;
  }

  Future<void> _recordNewItems(Map<String, Set<int>> before) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final institutionId = prefs.getInt('institution');
      final programmeId = authController.programmeId;

      // Only notify about items meant for this student's institution/programme.
      bool forUser(Map<String, Object?> r) {
        final rowInstitution = r['institutionId'] as int?;
        final rowProgramme = r['programmeId'] as int?;
        if (institutionId != null &&
            rowInstitution != null &&
            rowInstitution != institutionId) {
          return false;
        }
        if (programmeId != null &&
            rowProgramme != null &&
            rowProgramme != programmeId) {
          return false;
        }
        return true;
      }

      // Content only knows its course, so look up which programme that
      // course belongs to.
      final subjectRows =
      await db!.query('subjects', columns: ['id', 'programmeId']);
      final subjectProgramme = <int, int?>{
        for (final s in subjectRows)
          if (s['id'] is int) s['id'] as int: s['programmeId'] as int?,
      };
      bool contentForUser(Map<String, Object?> r) {
        final subjectProgrammeId = subjectProgramme[r['courseId']];
        return programmeId == null ||
            subjectProgrammeId == null ||
            subjectProgrammeId == programmeId;
      }

      await _recordNew(
        table: 'content',
        before: before,
        keep: contentForUser,
        titleOf: (r) => (r['title'] as String?) ?? 'New file',
        single: 'New file uploaded',
        plural: (n) => '$n new files uploaded',
        icon: 'content',
      );
      await _recordNew(
        table: 'announcements',
        before: before,
        keep: forUser,
        titleOf: (r) => (r['title'] as String?) ?? 'Announcement',
        single: 'New announcement posted',
        plural: (n) => '$n new announcements posted',
        icon: 'announcement',
      );
      await _recordNew(
        table: 'quizzes',
        before: before,
        keep: forUser,
        titleOf: _quizTitle,
        single: 'New assignment posted',
        plural: (n) => '$n new assignments posted',
        icon: 'quiz',
      );

      // Keep the feed from growing forever.
      final cutoff = DateTime.now()
          .subtract(const Duration(days: 60))
          .millisecondsSinceEpoch;
      await db!.delete('activity_log',
          where: 'timestamp < ?', whereArgs: [cutoff]);
    } catch (e) {
      // Notifications are a nice-to-have — never let them break the sync.
      print('❌ Error recording new items: $e');
    }
  }

  Future<void> _recordNew({
    required String table,
    required Map<String, Set<int>> before,
    required bool Function(Map<String, Object?>) keep,
    required String Function(Map<String, Object?>) titleOf,
    required String single,
    required String Function(int) plural,
    required String icon,
  }) async {
    final known = before[table] ?? <int>{};
    // Nothing was stored before this sync (first login, or the database was
    // just rebuilt), so everything would look "new" — skip rather than flood.
    if (known.isEmpty) return;

    final rows = await db!.query(table);
    final fresh = rows.where((r) {
      final id = r['id'];
      return id is int && !known.contains(id) && keep(r);
    }).toList();
    if (fresh.isEmpty) return;

    if (fresh.length > _maxIndividualEvents) {
      await _insertEvent(plural(fresh.length), 'Check the app for details', icon);
      return;
    }
    for (final r in fresh) {
      await _insertEvent(single, titleOf(r), icon);
    }
  }

  Future<void> _insertEvent(String action, String name, String icon) async {
    await db!.insert('activity_log', {
      'action': action,
      'name': name,
      'icon': icon,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    });
    print('🔔 $action — $name');
  }

  /// Quizzes are stored as JSON (QuizDto), so the title lives inside it.
  String _quizTitle(Map<String, Object?> r) {
    try {
      final m = jsonDecode(r['data'] as String) as Map<String, dynamic>;
      return (m['title'] as String?) ?? 'New assignment';
    } catch (_) {
      return 'New assignment';
    }
  }

  // ── Signed-in user's profile ──

  /// Endpoint that returns the signed-in user's details. Set this to whatever
  /// your backend exposes (the one your app already calls online to get the
  /// current user).
  static const String _profilePath = '/api/users/me';

  Future<void> _syncUserProfile(void Function(String)? onProgress) async {
    final profiles = UserProfileService(db: db);
    try {
      print('👤 Fetching user profile...');
      final res = await dio.get('$_baseUrl$_profilePath');
      final data = res.data;
      if (data is Map) {
        onProgress?.call('Loading your profile...');
        await profiles.saveFromServer(
          UserProfile.fromServerJson(Map<String, dynamic>.from(data)),
        );
        print('✅ User profile saved locally');
        return;
      }
      print('⚠️ Unexpected profile response: ${data.runtimeType}');
    } catch (e) {
      print('❌ Error syncing user profile: $e');
    }

    // Server unreachable (or the endpoint differs): keep at least the email
    // from the login token so pages still have something to show offline.
    final email = _emailFromToken(authController.token);
    if (email != null) await profiles.seedIfEmpty(email);
  }

  /// Best effort: reads the email / username claim from the JWT payload.
  String? _emailFromToken(String? token) {
    if (token == null) return null;
    try {
      final parts = token.split('.');
      if (parts.length != 3) return null;
      final payload =
      utf8.decode(base64Url.decode(base64Url.normalize(parts[1])));
      final claims = jsonDecode(payload) as Map<String, dynamic>;
      final value = claims['email'] ?? claims['sub'];
      return value is String && value.contains('@') ? value : null;
    } catch (_) {
      return null;
    }
  }

  // ── Offline file storage ──

  Future<Directory> _contentDir() async {
    final base = await getApplicationDocumentsDirectory();
    final dir = Directory(join(base.path, 'content'));
    if (!await dir.exists()) await dir.create(recursive: true);
    return dir;
  }

  /// Deterministic name: same content id + url => same file, so re-syncs
  /// (and DB drops on upgrade) never cause duplicate downloads.
  String _localFileName(int id, String url) {
    final segments = Uri.parse(url).pathSegments;
    final raw = segments.isNotEmpty ? Uri.decodeComponent(segments.last) : 'file';
    final safe = raw.replaceAll(RegExp(r'[^A-Za-z0-9._-]'), '_');
    return '${id}_$safe';
  }

  Future<String?> _downloadFile(int id, String url) async {
    final dir = await _contentDir();
    final file = File(join(dir.path, _localFileName(id, url)));

    if (await file.exists() && await file.length() > 0) return file.path;

    final tmp = File('${file.path}.part');
    try {
      // Separate Dio on purpose: the main one carries your Bearer token,
      // which shouldn't be sent to Supabase's public CDN.
      await Dio().download(url, tmp.path);
      await tmp.rename(file.path); // only appears once fully downloaded
      return file.path;
    } catch (e) {
      print('❌ Download failed for $url: $e');
      if (await tmp.exists()) await tmp.delete();
      return null;
    }
  }

  Future<void> downloadContentFiles({void Function(String)? onProgress}) async {
    // No local file system on web — lessons are opened from their URL.
    if (kIsWeb) return;
    final rows = await db!.query(
      'content',
      columns: ['id', 'title', 'fileUrl'],
      where: "fileUrl IS NOT NULL AND fileUrl != ''",
    );

    final validNames = <String>{};
    int done = 0;

    // 3 downloads at a time
    for (var i = 0; i < rows.length; i += 3) {
      final batch = rows.skip(i).take(3);
      await Future.wait(batch.map((row) async {
        final id = row['id'] as int;
        final url = row['fileUrl'] as String;
        validNames.add(_localFileName(id, url));

        final path = await _downloadFile(id, url);
        if (path != null) {
          await db!.update('content', {'localPath': path},
              where: 'id = ?', whereArgs: [id]);
        }
        done++;
        onProgress?.call('Downloading files ($done/${rows.length})...');
      }));
    }

    // Remove files for content that no longer exists on the server
    final dir = await _contentDir();
    await for (final entity in dir.list()) {
      if (entity is File &&
          !entity.path.endsWith('.part') &&
          !validNames.contains(basename(entity.path))) {
        await entity.delete();
      }
    }
    print('✅ Content files ready — $done processed');
  }

  /// Download a single file on demand (e.g. when a student taps a lesson
  /// that wasn't saved during startup sync) and record its local path.
  Future<String?> ensureLocalFile(int id, String url) async {
    if (kIsWeb) return null;
    final path = await _downloadFile(id, url);
    if (path != null && db != null) {
      await db!.update('content', {'localPath': path},
          where: 'id = ?', whereArgs: [id]);
    }
    return path;
  }
}