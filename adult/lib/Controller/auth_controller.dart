import 'package:flutter/material.dart';
import '../service/auth_service.dart';
import '../Model/user_model.dart';

class AuthController extends ChangeNotifier {
  final AuthService _authService = AuthService();
  UserModel? currentUser;
  bool isLoading = false;
  String? errorMessage;
  String? _role;
  String? _token;

  String? get token => _token;
  String? get role => _role;
  Future<void> init() async {
    isLoading = true;
    notifyListeners();

    _token = await _authService.getToken();
    _role = await _authService.getRole(); // ✅ Restore role too

    isLoading = false;
    notifyListeners();
  }

  void setAuthData(String token, String role) {
    _token = token;
    _role = role;
    notifyListeners();
  }

  Future<bool> login(String email, String password) async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      currentUser = await _authService.login(email, password);
      _token = currentUser?.token;
      _role = currentUser?.role;

      if (_token != null) {
        await _authService.saveToken(_token!);
      }

      isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      errorMessage = e.toString();
      isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> register({
    required String firstName,
    required String email,
    required String password,
    required String lastName,
    required int programmeId,
  }) async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      currentUser = await _authService.register(
        firstName: firstName,
        email: email,
        password: password,
        lastName: lastName,
        programmeId: programmeId,
      );
      isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      errorMessage = e.toString();
      isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // ✅ Clears everything on logout
  Future<void> logout() async {
    await _authService.logout();
    currentUser = null;
    _token = null;
    _role = null;
    notifyListeners();
  }
}
