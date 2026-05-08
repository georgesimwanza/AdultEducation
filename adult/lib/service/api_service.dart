import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  static const String baseUrl = 'http://10.0.2.2:8080/api';

  // ─── Token helpers ───────────────────────────────────────────────
  static Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('auth_token', token);
  }

  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token');
  }

  static Future<void> clearToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
  }

  // ─── Auth headers ─────────────────────────────────────────────────
  static Future<Map<String, String>> _authHeaders() async {
    final token = await getToken();
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  // ─── Content endpoints ────────────────────────────────────────────
  static Future<Map<String, dynamic>> addContent({
    required String title,
    required String type,
    required String fileUrl,
    required int courseId, // needed for backend relationship
  }) async {
    final headers = await _authHeaders();
    final response = await http.post(
      Uri.parse('$baseUrl/Content/addContent'),
      headers: headers,
      body: jsonEncode({
        'title': title,
        'type': type,
        'file_Url': fileUrl,
        'courseId': courseId,
      }),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      return jsonDecode(response.body);
    } else if (response.statusCode == 401) {
      await clearToken(); // token expired
      throw Exception('Unauthorized – please log in again');
    } else {
      throw Exception('Failed to add content: ${response.body}');
    }
  }

  static Future<List<Map<String, dynamic>>> getContentByCourseId(
    int courseId,
  ) async {
    final headers = await _authHeaders();
    final response = await http.get(
      Uri.parse('$baseUrl/Content/course/$courseId'),
      headers: headers,
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.cast<Map<String, dynamic>>();
    } else if (response.statusCode == 401) {
      await clearToken();
      throw Exception('Unauthorized – please log in again');
    } else {
      throw Exception('Failed to fetch content: ${response.body}');
    }
  }
}
