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
    print('=== Token from storage: $token ==='); // ← is token present?
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
    required int courseId,
  }) async {
    final headers = await _authHeaders();
    final body = jsonEncode({
      'title': title,
      'type': type,
      'file_Url': fileUrl,
      'courseId': courseId,
    });

    print('=== ApiService.addContent ===');
    print('URL: $baseUrl/Content/addContent');
    print('Headers: $headers');
    print('Body: $body');

    final response = await http.post(
      Uri.parse('$baseUrl/Content/addContent'),
      headers: headers,
      body: body,
    );

    print('=== Response ===');
    print('Status: ${response.statusCode}');
    print('Body: ${response.body}');

    if (response.statusCode == 200 || response.statusCode == 201) {
      return jsonDecode(response.body);
    } else if (response.statusCode == 401) {
      await clearToken();
      throw Exception('Unauthorized – please log in again');
    } else if (response.statusCode == 403) {
      throw Exception('Forbidden – make sure you are logged in as ADMIN');
    } else {
      throw Exception(
        'Failed to add content: ${response.statusCode} — ${response.body}',
      );
    }
  }

  static Future<List<Map<String, dynamic>>> getContentByCourseId(
    int courseId,
  ) async {
    final headers = await _authHeaders();

    print('=== ApiService.getContentByCourseId ===');
    print('URL: $baseUrl/Content/course/$courseId');

    final response = await http.get(
      Uri.parse('$baseUrl/Content/course/$courseId'),
      headers: headers,
    );

    print('Status: ${response.statusCode}');
    print('Body: ${response.body}');

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.cast<Map<String, dynamic>>();
    } else if (response.statusCode == 401) {
      await clearToken();
      throw Exception('Unauthorized – please log in again');
    } else if (response.statusCode == 403) {
      throw Exception('Forbidden – make sure you are logged in as ADMIN');
    } else {
      throw Exception(
        'Failed to fetch content: ${response.statusCode} — ${response.body}',
      );
    }
  }

  //USER BASED APIS
}
