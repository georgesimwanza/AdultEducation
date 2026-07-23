import 'dart:convert';
import 'package:adult/Model/Announcement_model.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class AnnouncementService {
  final String baseUrl = 'http://10.0.2.2:8080';

  Future<Map<String, String>> _headers() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  Future<List<AnnouncementModel>> getAll() async {
    final res = await http.get(
      Uri.parse('$baseUrl/api/announcements'),
      headers: await _headers(),
    );
    if (res.statusCode == 200) {
      final List data = jsonDecode(res.body);
      return data.map((e) => AnnouncementModel.fromJson(e)).toList();
    }
    throw Exception('Failed to load announcements: ${res.statusCode}');
  }

  Future<List<AnnouncementModel>> getByProgramme(int programmeId) async {
    final res = await http.get(
      Uri.parse('$baseUrl/api/announcements/programme/$programmeId'),
      headers: await _headers(),
    );
    if (res.statusCode == 200) {
      final List data = jsonDecode(res.body);
      return data.map((e) => AnnouncementModel.fromJson(e)).toList();
    }
    throw Exception('Failed to load announcements: ${res.statusCode}');
  }

  Future<List<AnnouncementModel>> getByInstitution(int institutionId) async {
    final res = await http.get(
      Uri.parse('$baseUrl/api/announcements/institution/$institutionId'),
      headers: await _headers(),
    );
    if (res.statusCode == 200) {
      final List data = jsonDecode(res.body);
      return data.map((e) => AnnouncementModel.fromJson(e)).toList();
    }
    throw Exception('Failed to load announcements: ${res.statusCode}');
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
      return data.map((e) => AnnouncementModel.fromJson(e)).toList();
    }
    throw Exception('Failed to load announcements: ${res.statusCode}');
  }

  Future<AnnouncementModel> create(AnnouncementModel announcement) async {
    final res = await http.post(
      Uri.parse('$baseUrl/api/announcements'),
      headers: await _headers(),
      body: jsonEncode(announcement.toJson()),
    );
    if (res.statusCode == 201) {
      return AnnouncementModel.fromJson(jsonDecode(res.body));
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
      return AnnouncementModel.fromJson(jsonDecode(res.body));
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
  }
}
