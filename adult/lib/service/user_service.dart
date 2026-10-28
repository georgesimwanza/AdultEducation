import 'dart:convert';
import 'package:adult/Model/user_model.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';
import 'package:adult/service/activity_log_service.dart';
import 'package:adult/service/api_config.dart';

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
    final response = await http.get(
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

  Future<void> addStudent(String fullName, String email) async {
    final parts = fullName.trim().split(' ');
    final response = await http.post(
      Uri.parse('$baseUrl/AllStudents'),
      headers: await _authHeaders(),
      body: jsonEncode({
        'firstName': parts.first,
        'lastName': parts.length > 1 ? parts.skip(1).join(' ') : '',
        'email': email,
      }),
    );
    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception('Failed to add student: ${response.statusCode}');
    }
    if (db != null) {
      await ActivityLogService(
        db: db!,
      ).log(action: 'New student enrolled', name: fullName, icon: 'person');
    }
  }

  Future<void> deleteStudent(int id, {String? name}) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/AllStudents/$id'),
      headers: await _authHeaders(),
    );
    if (response.statusCode != 200 && response.statusCode != 204) {
      throw Exception('Failed to delete student: ${response.statusCode}');
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
    final response = await http.get(
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
