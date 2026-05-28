import 'package:flutter/material.dart';
import '../service/auth_service.dart';
import '../Model/user_model.dart';
import 'package:adult/service/sync_service.dart';

class AuthController extends ChangeNotifier {
  final AuthService _authService = AuthService();
  UserModel? currentUser;
  bool isLoading = false;
  String? errorMessage;
  String? _role;
  String? _token;
  int? _programmeId;
  int? get programmeId => _programmeId;
  String? get token => _token;
  String? get role => _role;
  Future<void> init() async {
    isLoading = true;
    notifyListeners();

    _token = await _authService.getToken();
    _role = await _authService.getRole();
    _programmeId = await _authService.getProgrammeId();
    print('🔑 Token on restart: $_token'); // ✅ add this
    print('👤 Role on restart: $_role');
    print('📚 Programme ID on restart: $_programmeId');

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
      _programmeId = currentUser?.programmeId; // ✅ set in memory

      if (_token != null) {
        await _authService.saveToken(_token!);
      }
      if (_role != null) {
        print('💾 Saving role: $_role');
        await _authService.saveRole(_role!);
      }
      if (currentUser?.programmeId != null) {
        await _authService.saveProgrammeId(currentUser!.programmeId!); // ✅
      }
      if (_programmeId != null) {
        print('💾 Saving programmeId: $_programmeId'); // ✅
        await _authService.saveProgrammeId(_programmeId!);
      } else {
        print('❌ programmeId is null, not saving');
      }
      final syncService = SyncService(authController: this);
      await syncService.syncOnStartup();
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

  Future<void> logout() async {
    await _authService.logout();
    currentUser = null;
    _token = null;
    _role = null;
    _programmeId = null;
    notifyListeners();
  }
}
