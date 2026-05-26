import 'package:dio/dio.dart';
import 'package:sqflite/sqflite.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path/path.dart';
import 'package:adult/Controller/auth_controller.dart'; // ← add this

class SyncService {
  final AuthController authController;
  final Dio dio = Dio(); // ← add this
  Database? db;

  static const String _baseUrl = 'http://10.0.2.2:8080';

  SyncService({required this.authController}); // ← constructor

  Future<void> initDb() async {
    print('🗄️ Initializing database...');
    final dbPath = await getDatabasesPath();
    db = await openDatabase(
      join(dbPath, 'app.db'),
      version: 1,
      onCreate: (db, version) async {
        print('🗄️ Creating tables...');
        await db.execute('''
          CREATE TABLE subjects (
            id INTEGER PRIMARY KEY,
            courseCode TEXT,
            courseName TEXT,
            description TEXT
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
        print('✅ Tables created successfully');
      },
    );
    print('✅ Database initialized');
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

  Future<void> syncOnStartup() async {
    print('🚀 Starting sync on startup...');
    await initDb();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('last_sync_timestamp');
    print('🧹 Cleared timestamp — forcing full download');
    // ← attach token from AuthController
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

    await Future.wait([_syncSubjects(lastSync), _syncContent(lastSync)]);

    await saveLastSyncTimestamp();
    print('✅ Sync completed successfully');
  }

  Future<void> _syncSubjects(int? since) async {
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

  Future<void> _syncContent(int? since) async {
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
}
