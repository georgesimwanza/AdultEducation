import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:sqflite/sqflite.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path/path.dart';
import 'package:adult/Controller/auth_controller.dart';

class SyncService {
  final AuthController authController;
  final Dio dio = Dio();
  Database? db;

  static const String _baseUrl = 'http://10.0.2.2:8080';

  SyncService({required this.authController});

  Future<void> initDb() async {
    print('🗄️ Initializing database...');
    final dbPath = await getDatabasesPath();
    db = await openDatabase(
      join(dbPath, 'app.db'),
      version: 6, // ← bumped to 6 (added institutions cache table)
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
            institutionId INTEGER
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
            courseId INTEGER
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

    onProgress?.call('Loading content locally...');
    await Future.wait([
      _syncSubjects(lastSync, onProgress),
      _syncContent(lastSync, onProgress),
      _syncProgrammes(lastSync, onProgress),
      _syncAnnouncements(lastSync, onProgress), // ← added
      _syncQuizzes(lastSync, onProgress), // ← added
    ]);

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

      for (var item in data) {
        await db!.insert('quizzes', {
          'id': item['id'],
          'courseId': item['course'] != null ? item['course']['id'] : null,
          'institutionId': item['institution'] != null
              ? item['institution']['id']
              : null,
          'programmeId': item['programme'] != null
              ? item['programme']['id']
              : null,
          'data': jsonEncode(item),
        }, conflictAlgorithm: ConflictAlgorithm.replace);
        print('💾 Saved quiz: ${item['title']}');
      }

      print('✅ Quizzes sync done — ${data.length} records saved');
    } catch (e) {
      print('❌ Error syncing quizzes: $e');
    }
  }
}
