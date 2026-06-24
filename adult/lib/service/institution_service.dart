import 'dart:convert';
import 'package:adult/Model/insititution.dart';
import 'package:http/http.dart' as http;

class InstitutionService {
  static const String institutionBaseUrl =
      'http://10.0.2.2:8080/api/institution';

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
      return Institution.fromJson(jsonDecode(response.body));
    } else if (response.statusCode == 409) {
      throw Exception('Institution already exists');
    } else {
      throw Exception('Failed to register institution: ${response.statusCode}');
    }
  }
}
