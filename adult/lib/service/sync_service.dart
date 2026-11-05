import 'dart:async';
import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:sqflite_common/sqlite_api.dart';
import 'package:adult/service/platform/app_database.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:adult/Controller/auth_controller.dart';
import 'package:adult/service/user_profile_service.dart';
import 'package:adult/service/api_config.dart';
import 'package:adult/service/lms_api.dart';
import 'package:adult/service/offline_cache.dart';
import 'package:adult/service/media/media_store.dart';
import 'package:adult/service/notifications/notification_service.dart';

class SyncService {
  final AuthController authController;
  final Dio dio = Dio();
  Database? db;

  static const String _baseUrl = '$kBackendHost';

  SyncService({required this.authController});

  Future<void> initDb() async {
    // Re-syncs after reconnecting reuse the open db that screens already hold.
    if (db != null && db!.isOpen) {
      await OfflineCache.attach(db!);
      await MediaStore.instance.attach(db!);
      return;
    }
    print('🗄️ Initializing database...');
    // In the browser this is sqlite compiled to WASM, stored in IndexedDB.
    db = await openAppDatabase(
      'app.db',
      OpenDatabaseOptions(
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
      ),
    );
    await OfflineCache.attach(db!);
    await MediaStore.instance.attach(db!);
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
  ///
  /// Anything new it finds is shown as a notification. [prefetchPages] is
  /// off for the background check, to keep it light on data.
  Future<void> syncOnStartup({
    void Function(String stage)? onProgress,
    bool prefetchPages = true,
  }) async {
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

    // Changes made offline go up first, so the downloads below include them.
    if (await OfflineCache.pendingCount() > 0) {
      onProgress?.call('Sending changes made offline...');
      final sent = await OfflineCache.flush();
      print('📤 Sent $sent offline changes');
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

    final fresh = await _recordNewItems(before);

    if (prefetchPages) {
      onProgress?.call('Saving your pages for offline use...');
      await _prefetchPages();
    }

    onProgress?.call('Finishing up...');
    await saveLastSyncTimestamp();
    print('✅ Sync completed successfully');

    // Only when something new arrived: an empty sync stays silent.
    await NotificationService.notifyNewItems(fresh);

    // Phone: save every lesson file so it opens offline. Runs on after the
    // sync returns; the "Loading content" banner shows its progress.
    if (prefetchPages) unawaited(_saveLessonFiles());
  }

  /// Files of this student's programme (everything if it isn't known).
  Future<void> _saveLessonFiles() async {
    final media = MediaStore.instance;
    if (!media.canDownload) return;
    try {
      final programmeId = authController.programmeId;
      final rows = programmeId == null
          ? await db!.query('content', columns: ['fileUrl'])
          : await db!.rawQuery(
              'SELECT c.fileUrl FROM content c JOIN subjects s ON s.id = c.courseId '
              'WHERE s.programmeId = ?',
              [programmeId]);
      await media.downloadAll(rows.map((r) => (r['fileUrl'] as String?) ?? ''));
    } catch (e) {
      print('❌ Error saving lesson files: $e');
    }
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

  // ── Pages read through LmsApi and the other online services ──
  // Loading each one now saves it in OfflineCache, so every screen opens
  // offline even if it wasn't visited while online.

  Future<void> _prefetchPages() async {
    final role = authController.role;
    final staff = role == 'ADMIN' || role == 'INSTITUTION' || role == 'INSTRUCTOR';
    final prefs = await SharedPreferences.getInstance();
    final institutionId = prefs.getInt('institution');
    final programmeId = authController.programmeId;

    final lmsPaths = [
      '/profile',
      '/profile/education-levels',
      '/notifications',
      '/notifications/unread-count',
      '/messages/unread-count',
      '/messages/contacts',
      if (!staff) ...[
        '/reports/dashboard/learner',
        '/reports/me',
        '/enrollments/me',
        '/enrollments/catalogue',
        '/assignments/mine',
      ],
      if (staff) ...[
        '/course/manage',
        '/assignments/manage',
        '/reports/dashboard/admin',
        '/reports/courses',
        '/reports/participation',
        '/quizzes${institutionId != null ? '?institutionId=$institutionId' : ''}',
        if (role != 'INSTRUCTOR') '/admin/users',
      ],
    ];
    final headers = await authHeaders();
    Future<void> get(String url) async {
      try {
        await cachedGet(Uri.parse(url), headers: headers);
      } catch (e) {
        print('⚠️ Could not save $url for offline use: $e');
      }
    }

    await Future.wait([
      for (final p in lmsPaths) get(LmsApi.url(p)),
      get('$_baseUrl/api/programmes/allProgrammes'),
      get('$_baseUrl/api/institution/institutions'),
      get('$_baseUrl/api/Content/getAllContent'),
      if (programmeId != null) get('$_baseUrl/api/programmes/$programmeId/title'),
      if (staff) get('$_baseUrl/api/announcement/allAnnouncements'),
      if (staff && institutionId != null) ...[
        get('$_baseUrl/api/users/institution/$institutionId'),
        get('$_baseUrl/api/users/count/$institutionId'),
      ],
    ]);

    // Each open conversation, so chats can be read offline.
    try {
      final list = await LmsApi.get('/messages/conversations') as List;
      await Future.wait([
        for (final c in list) get(LmsApi.url('/messages/with/${c['userId']}')),
      ]);
    } catch (e) {
      print('⚠️ Could not save conversations for offline use: $e');
    }
    print('✅ Pages saved for offline use');
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

  /// Logs what this sync added and returns it, for the notification.
  Future<List<NewItem>> _recordNewItems(Map<String, Set<int>> before) async {
    final fresh = <NewItem>[];
    // Nothing stored before this sync (first login, or the database was just
    // rebuilt): everything would look new, so don't flood the user.
    if (before.values.every((ids) => ids.isEmpty)) return fresh;
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
        into: fresh,
        table: 'content',
        before: before,
        keep: contentForUser,
        titleOf: (r) => (r['title'] as String?) ?? 'New file',
        single: 'New file uploaded',
        plural: (n) => '$n new files uploaded',
        icon: 'content',
      );
      await _recordNew(
        into: fresh,
        table: 'announcements',
        before: before,
        keep: forUser,
        titleOf: (r) => (r['title'] as String?) ?? 'Announcement',
        single: 'New announcement posted',
        plural: (n) => '$n new announcements posted',
        icon: 'announcement',
      );
      await _recordNew(
        into: fresh,
        table: 'quizzes',
        before: before,
        keep: forUser,
        titleOf: _quizTitle,
        single: 'New quiz posted',
        plural: (n) => '$n new quizzes posted',
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
    return fresh;
  }

  Future<void> _recordNew({
    required List<NewItem> into,
    required String table,
    required Map<String, Set<int>> before,
    required bool Function(Map<String, Object?>) keep,
    required String Function(Map<String, Object?>) titleOf,
    required String single,
    required String Function(int) plural,
    required String icon,
  }) async {
    final known = before[table] ?? <int>{};

    final rows = await db!.query(table);
    final fresh = rows.where((r) {
      final id = r['id'];
      return id is int && !known.contains(id) && keep(r);
    }).toList();
    if (fresh.isEmpty) return;

    if (fresh.length > _maxIndividualEvents) {
      await _insertEvent(plural(fresh.length), 'Check the app for details', icon);
      into.add(NewItem(plural(fresh.length), 'Open the app to see them'));
      return;
    }
    for (final r in fresh) {
      await _insertEvent(single, titleOf(r), icon);
      into.add(NewItem(single, titleOf(r)));
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
      return (m['title'] as String?) ?? 'New quiz';
    } catch (_) {
      return 'New quiz';
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
}
