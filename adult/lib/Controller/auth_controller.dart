import 'package:flutter/material.dart';
import '../service/auth_service.dart';
import '../Model/user_model.dart';

class AuthController extends ChangeNotifier {
  final AuthService _authService = AuthService();
  UserModel? currentUser;
  bool isLoading = false;
  String? errorMessage;

  Future<bool> login(String email, String password) async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      currentUser = await _authService.login(email, password);
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
    required int programmeId, // ← was String course
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
        programmeId: programmeId, // ← passed directly, no parsing needed
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

  Future<void> logout() async {
    await _authService.logout();
    currentUser = null;
    notifyListeners();
  }
}
