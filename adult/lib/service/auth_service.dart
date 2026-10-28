import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../Model/user_model.dart';
import 'package:adult/service/api_config.dart';

/// Handles all authentication-related network requests and local
/// persistence (auth token, role, programme, and institution) using
/// [SharedPreferences].
class AuthService {
  /// Base URL for the user API. Points at the Android emulator's
  /// loopback alias (10.0.2.2) for the local backend during development.
  final String baseUrl = '$kBackendHost/api/users';

  /// Registers a new user account with the backend.
  ///
  /// Sends the user's personal details, chosen programme, and
  /// institution to the `/Register` endpoint. Returns the created
  /// [UserModel] on success, or throws an [Exception] containing the
  /// response body if registration fails.
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

  /// Persists the signed-in user's role (e.g. student, admin) to local
  /// storage so it can be read again without another network call.
  Future<void> saveRole(String role) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('auth_role', role);
  }

  /// Reads the previously saved user role from local storage.
  ///
  /// Returns `null` if no role has been saved yet.
  Future<String?> getRole() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_role');
  }

  /// Logs a user in with their [email] and [password].
  ///
  /// Posts credentials to the `/login` endpoint and returns the
  /// resulting [UserModel] (including auth token, role, and programme
  /// id) on success. Throws an [Exception] containing the response body
  /// if login fails.
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

  /// Persists the auth [Token] returned at login so it can be attached
  /// to future authenticated requests.
  Future<void> saveToken(String Token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('auth_token', Token);
  }

  /// Reads the previously saved auth token from local storage.
  ///
  /// Returns `null` if the user is not currently logged in.
  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token');
  }

  /// Persists the signed-in user's programme [id] to local storage.
  Future<void> saveProgrammeId(int id) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('programme_id', id);
  }

  /// Reads the previously saved programme id from local storage.
  ///
  /// Returns `null` if no programme id has been saved yet.
  Future<int?> getProgrammeId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt('programme_id');
  }

  /// Logs the user out by clearing the stored auth token.
  ///
  /// Note: this only removes 'auth_token'; role, programme id, and
  /// institution remain in storage unless cleared separately.
  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
  }

  /// Persists the signed-in user's [institution] id to local storage.
  Future<void> saveInstitution(int institution) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('institution', institution);
  }

  /// Reads the previously saved institution id from local storage.
  ///
  /// Returns `null` if no institution id has been saved yet.
  Future<int?> getInstitution() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt('institution');
  }
}
