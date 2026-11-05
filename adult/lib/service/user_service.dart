import 'dart:math';
import 'dart:convert';
import 'package:adult/Model/user_model.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common/sqlite_api.dart';
import 'package:adult/service/activity_log_service.dart';
import 'package:adult/service/api_config.dart';
import 'package:adult/service/offline_cache.dart';

class UserService {
  final String baseUrl = "$kBackendHost/api/users";

  // Optional — pass the shared local db to also log successful
  // add/delete actions to the local, backend-free activity feed shown on
  // the dashboard. Omit it and this behaves exactly as before.
  final Database? db;

  UserService({this.db});

  Future<Map<String, String>> _authHeaders() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token') ?? '';
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  Future<List<UserModel>> getStudentsByInstitution() async {
    final prefs = await SharedPreferences.getInstance();
    final institution = await prefs.getInt('institution') ?? '';
    print('Institution from prefs: $institution');
    final response = await cachedGet(
      Uri.parse('$baseUrl/institution/$institution'),
      headers: await _authHeaders(),
    );
    print('Status: ${response.statusCode}');
    print('Body: ${response.body}');
    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => UserModel.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load students: ${response.statusCode}');
    }
  }

  /// Creates a learner account with a temporary password and returns that
  /// password so the admin can give it to the learner (who can change it
  /// in Account settings).
  Future<String> addStudent(String fullName, String email) async {
    final parts = fullName.trim().split(RegExp(r'\s+'));
    final password = _temporaryPassword();
    final response = await http.post(
      Uri.parse('$kBackendHost/api/admin/users'),
      headers: await _authHeaders(),
      body: jsonEncode({
        'firstName': parts.first,
        'lastName': parts.length > 1 ? parts.skip(1).join(' ') : '-',
        'email': email.trim(),
        'password': password,
        'role': 'LEARNER',
      }),
    );
    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception(_message(response, 'Failed to add student'));
    }
    if (db != null) {
      await ActivityLogService(
        db: db!,
      ).log(action: 'New student enrolled', name: fullName, icon: 'person');
    }
    return password;
  }

  // Easy to read aloud: no 0/O or 1/l look-alikes
  static String _temporaryPassword() {
    const chars = 'abcdefghjkmnpqrstuvwxyz23456789';
    final r = Random.secure();
    return List.generate(10, (_) => chars[r.nextInt(chars.length)]).join();
  }

  static String _message(http.Response response, String fallback) {
    try {
      final body = jsonDecode(response.body);
      if (body is Map && body['message'] != null) return body['message'].toString();
    } catch (_) {}
    return '$fallback (${response.statusCode})';
  }

  /// Deactivates the account rather than deleting it, so the learner's
  /// grades, attendance and history stay in reports. Reactivate it from
  /// the Users screen.
  Future<void> deleteStudent(int id, {String? name}) async {
    final response = await http.patch(
      Uri.parse('$kBackendHost/api/admin/users/$id/status'),
      headers: await _authHeaders(),
      body: jsonEncode({'active': false}),
    );
    if (response.statusCode != 200 && response.statusCode != 204) {
      throw Exception(_message(response, 'Failed to remove student'));
    }
    if (db != null) {
      await ActivityLogService(db: db!).log(
        action: 'Student removed',
        name: name ?? 'Student #$id',
        icon: 'person',
      );
    }
  }

  Future<int> countStudentsByInstitution() async {
    final prefs = await SharedPreferences.getInstance();
    final institutionId = prefs.getInt('institution') ?? 0;
    print('🏫 Counting students for institution ID: $institutionId');
    final response = await cachedGet(
      Uri.parse('$baseUrl/count/$institutionId'),
      headers: await _authHeaders(),
    );
    print('📊 Count status: ${response.statusCode}');
    print('📊 Count body: ${response.body}');
    if (response.statusCode == 200) {
      final count = int.parse(response.body);
      print('✅ Student count: $count');
      return count;
    } else {
      throw Exception('Failed to count students: ${response.statusCode}');
    }
  }
}
