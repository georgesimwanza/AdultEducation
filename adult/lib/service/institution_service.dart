import 'dart:convert';
import 'package:adult/Model/insititution.dart';
import 'package:http/http.dart' as http;
import 'package:adult/service/api_config.dart';

class InstitutionService {
  static const String institutionBaseUrl =
      '$kBackendHost/api/institution';

  Future<List<Institution>> getInstitutions() async {
    final response = await http.get(
      Uri.parse('$institutionBaseUrl/institutions'),
    );
    if (response.statusCode == 200) {
      final List data = jsonDecode(response.body);
      return data.map((e) => Institution.fromJson(e)).toList();
    } else {
      throw Exception('Failed to load institutions: ${response.statusCode}');
    }
  }

  Future<Institution> registerInstitution({
    required String name,
    required String email,
    required String location,
    required String password,
  }) async {
    final response = await http.post(
      Uri.parse('$institutionBaseUrl/register'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'name': name,
        'email': email,
        'location': location,
        'password': password,
      }),
    );
    if (response.statusCode == 200 || response.statusCode == 201) {
      // The endpoint answers with the new admin's login payload
      // (institutionId / institutionName), not an Institution object.
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      return Institution(
        id: (data['institutionId'] ?? data['id']) as int,
        name: (data['institutionName'] ?? data['name'] ?? name) as String,
      );
    } else if (response.statusCode == 409) {
      throw Exception('Institution already exists');
    } else {
      throw Exception('Failed to register institution: ${response.statusCode}');
    }
  }

  /// Used by the dashboard's institution-name lookup. There's no
  /// single-institution-by-id endpoint here, so this goes through the
  /// existing getInstitutions() list and finds the match client-side
  /// rather than guessing at an endpoint that might not exist. Returns
  /// null on any failure (offline, not found) so callers can fall back to
  /// a placeholder.
  Future<String?> getInstitutionName(int institutionId) async {
    try {
      final institutions = await getInstitutions();
      for (final institution in institutions) {
        if (institution.id == institutionId) {
          return institution.name;
        }
      }
      return null;
    } catch (e) {
      return null;
    }
  }
}
