import 'dart:convert';
import 'package:adult/Model/Announcement_model.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';

/// Pass [db] (the same local db SyncService/QuizService use) to get offline
/// support on the read methods: a successful network call caches results
/// locally (write-through), and a failed one — like the SocketException you
/// hit with no backend reachable — falls back to whatever's cached from the
/// last sync. create/update/delete stay network-only but keep the local
/// cache in sync on success, so other screens don't see stale data.
///
/// Assumes AnnouncementModel.fromJson reads nested `institution.id` /
/// `programme.id`, matching how the Announcement entity serializes on the
/// backend — adjust _rowToJson below if your model expects a flatter shape.
class AnnouncementService {
  AnnouncementService({this.db});

  final String baseUrl = 'http://10.0.2.2:8080';
  final Database? db;

  Future<Map<String, String>> _headers() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  Future<List<AnnouncementModel>> getAll() async {
    try {
      final res = await http.get(
        Uri.parse('$baseUrl/api/announcements'),
        headers: await _headers(),
      );
      if (res.statusCode == 200) {
        final List data = jsonDecode(res.body);
        if (db != null) {
          for (final item in data) {
            await _cacheAnnouncement(item as Map<String, dynamic>);
          }
        }
        return data.map((e) => AnnouncementModel.fromJson(e)).toList();
      }
      throw Exception('Failed to load announcements: ${res.statusCode}');
    } catch (e) {
      if (db == null) rethrow;
      return _readLocal();
    }
  }

  Future<List<AnnouncementModel>> getByProgramme(int programmeId) async {
    try {
      final res = await http.get(
        Uri.parse('$baseUrl/api/announcements/programme/$programmeId'),
        headers: await _headers(),
      );
      if (res.statusCode == 200) {
        final List data = jsonDecode(res.body);
        if (db != null) {
          for (final item in data) {
            await _cacheAnnouncement(item as Map<String, dynamic>);
          }
        }
        return data.map((e) => AnnouncementModel.fromJson(e)).toList();
      }
      throw Exception('Failed to load announcements: ${res.statusCode}');
    } catch (e) {
      if (db == null) rethrow;
      return _readLocal(programmeId: programmeId);
    }
  }

  Future<List<AnnouncementModel>> getByInstitution(int institutionId) async {
    try {
      final res = await http.get(
        Uri.parse('$baseUrl/api/announcements/institution/$institutionId'),
        headers: await _headers(),
      );
      if (res.statusCode == 200) {
        final List data = jsonDecode(res.body);
        if (db != null) {
          for (final item in data) {
            await _cacheAnnouncement(item as Map<String, dynamic>);
          }
        }
        return data.map((e) => AnnouncementModel.fromJson(e)).toList();
      }
      throw Exception('Failed to load announcements: ${res.statusCode}');
    } catch (e) {
      if (db == null) rethrow;
      return _readLocal(institutionId: institutionId);
    }
  }

  /// Reads institutionId and programmeId from SharedPreferences and
  /// fetches announcements scoped to both.
  Future<List<AnnouncementModel>>
  getByInstitutionAndProgrammeFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final institutionId = prefs.getInt('institution');
    final programmeId = prefs.getInt('programme_id');

    if (institutionId == null || programmeId == null) {
      throw Exception(
        'Missing institutionId or programmeId in SharedPreferences',
      );
    }

    return getByInstitutionAndProgramme(institutionId, programmeId);
  }

  /// Same as above, but takes the IDs directly if you already have them.
  Future<List<AnnouncementModel>> getByInstitutionAndProgramme(
    int institutionId,
    int programmeId,
  ) async {
    try {
      final uri =
          Uri.parse(
            '$baseUrl/api/announcement/getByInstitutionAndProgramme',
          ).replace(
            queryParameters: {
              'institutionId': institutionId.toString(),
              'programmeId': programmeId.toString(),
            },
          );

      final res = await http.get(uri, headers: await _headers());

      if (res.statusCode == 200) {
        final List data = jsonDecode(res.body);
        if (db != null) {
          for (final item in data) {
            await _cacheAnnouncement(item as Map<String, dynamic>);
          }
        }
        return data.map((e) => AnnouncementModel.fromJson(e)).toList();
      }
      throw Exception('Failed to load announcements: ${res.statusCode}');
    } catch (e) {
      if (db == null) rethrow;
      // Offline — e.g. the SocketException from an unreachable backend.
      // Serve whatever was cached during the last successful sync.
      return _readLocal(institutionId: institutionId, programmeId: programmeId);
    }
  }

  Future<AnnouncementModel> create(AnnouncementModel announcement) async {
    final res = await http.post(
      Uri.parse('$baseUrl/api/announcements'),
      headers: await _headers(),
      body: jsonEncode(announcement.toJson()),
    );
    if (res.statusCode == 201) {
      final saved = AnnouncementModel.fromJson(jsonDecode(res.body));
      if (db != null) await _cacheAnnouncement(jsonDecode(res.body));
      return saved;
    }
    throw Exception('Failed to create announcement: ${res.statusCode}');
  }

  Future<AnnouncementModel> update(
    String id,
    AnnouncementModel announcement,
  ) async {
    final res = await http.put(
      Uri.parse('$baseUrl/api/announcements/$id'),
      headers: await _headers(),
      body: jsonEncode(announcement.toJson()),
    );
    if (res.statusCode == 200) {
      final saved = AnnouncementModel.fromJson(jsonDecode(res.body));
      if (db != null) await _cacheAnnouncement(jsonDecode(res.body));
      return saved;
    }
    throw Exception('Failed to update announcement: ${res.statusCode}');
  }

  Future<void> delete(String id) async {
    final res = await http.delete(
      Uri.parse('$baseUrl/api/announcements/$id'),
      headers: await _headers(),
    );
    if (res.statusCode != 204) {
      throw Exception('Failed to delete announcement: ${res.statusCode}');
    }
    final announcementId = int.tryParse(id);
    if (db != null && announcementId != null) {
      await db!.delete(
        'announcements',
        where: 'id = ?',
        whereArgs: [announcementId],
      );
    }
  }

  // ---------- local cache (only used when db is provided) ----------

  Future<void> _cacheAnnouncement(Map<String, dynamic> json) async {
    await db!.insert('announcements', {
      'id': json['id'],
      'institutionId': json['institution'] != null
          ? json['institution']['id']
          : null,
      'programmeId': json['programme'] != null ? json['programme']['id'] : null,
      'title': json['title'],
      'content': json['content'],
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<AnnouncementModel>> _readLocal({
    int? institutionId,
    int? programmeId,
  }) async {
    final where = <String>[];
    final args = <Object>[];
    if (institutionId != null) {
      where.add('institutionId = ?');
      args.add(institutionId);
    }
    if (programmeId != null) {
      where.add('programmeId = ?');
      args.add(programmeId);
    }

    final rows = await db!.query(
      'announcements',
      where: where.isEmpty ? null : where.join(' AND '),
      whereArgs: where.isEmpty ? null : args,
    );

    return rows
        .map(
          (r) => AnnouncementModel.fromJson({
            'id': r['id'],
            'institution': {'id': r['institutionId']},
            'programme': {'id': r['programmeId']},
            'title': r['title'],
            'content': r['content'],
          }),
        )
        .toList();
  }
}
