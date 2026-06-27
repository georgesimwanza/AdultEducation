import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../Model/user_model.dart';

class AuthService {
  final String baseUrl = 'http://10.0.2.2:8080/api/users';
  Future<UserModel> register({
    required String firstName,
    required String lastName,
    required String email,
    required String password,
    required int programmeId,
    required int institutionId,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/Register'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'firstName': firstName,
        'lastName': lastName,
        'email': email,
        'passwordHash': password,
        'selectedProgramme': {'id': programmeId},
        'institutionId': institutionId,
      }),
    );
    if (response.statusCode == 200) {
      return UserModel.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('registration failed : ${response.body}');
    }
  }

  Future<void> saveRole(String role) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('auth_role', role);
  }

  Future<String?> getRole() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_role');
  }

  Future<UserModel> login(String email, String password) async {
    final response = await http.post(
      Uri.parse('$baseUrl/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'password': password}),
    );

    print('LOGIN BODY: ${response.body}');

    if (response.statusCode == 200) {
      final user = UserModel.fromJson(jsonDecode(response.body));
      print('USER ROLE: ${user.role}');
      print('USER TOKEN: ${user.token}');
      print('🔍 user.programmeId: ${user.programmeId}');
      return user;
    } else {
      throw Exception('Login failed: ${response.body}');
    }
  }

  Future<void> saveToken(String Token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('auth_token', Token);
  }

  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token');
  }

  Future<void> saveProgrammeId(int id) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('programme_id', id);
  }

  Future<int?> getProgrammeId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt('programme_id');
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
  }

  Future<void> saveInstitution(int institution) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('institution', institution);
  }

  Future<int?> getInstitution() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt('institution_id');
  }
}
