import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../service/auth_service.dart';
import '../Model/user_model.dart';
import 'package:adult/service/offline_cache.dart';
import 'package:adult/service/notifications/notification_service.dart';
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
  /// Signed-in email. After a restart only the token is kept, so it comes
  /// from the token's subject.
  String? get email => currentUser?.email ?? tokenClaims(_token)?['sub'] as String?;
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

  /// The login token lasts 24 hours. Once it has run out the server refuses
  /// every request, so the learner must sign in again.
  bool get tokenExpired {
    final exp = tokenClaims(_token)?['exp'];
    return exp is int &&
        DateTime.fromMillisecondsSinceEpoch(exp * 1000).isBefore(DateTime.now());
  }

  /// Payload of a JWT, or null if [token] isn't one.
  static Map<String, dynamic>? tokenClaims(String? token) {
    final parts = token?.split('.');
    if (parts == null || parts.length != 3) return null;
    try {
      return jsonDecode(utf8.decode(base64Url.decode(base64Url.normalize(parts[1]))))
          as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }

  /// Signs out because the token ran out, and says so on the login screen.
  /// Unlike [logout], pages saved for offline use are kept: it is usually
  /// the same person signing straight back in.
  Future<void> expireSession() async {
    if (_token == null) return;
    await _authService.logout();
    _token = null;
    _role = null;
    _programmeId = null;
    currentUser = null;
    errorMessage = 'Your session has expired. Please sign in again.';
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
      _programmeId = currentUser?.programmeId;

      if (_token != null) {
        await _authService.saveToken(_token!);
      }
      // Someone else used this device last: drop their saved pages.
      final prefs = await SharedPreferences.getInstance();
      if (prefs.getString('offline_cache_owner') != email.toLowerCase()) {
        await OfflineCache.clear();
        await prefs.setString('offline_cache_owner', email.toLowerCase());
      }
      if (_role != null) {
        print('💾 Saving role: $_role');
        await _authService.saveRole(_role!);
      }
      if (currentUser?.institutionId != null) {
        print('💾 Saving institution: ${currentUser!.institutionId}');
        await _authService.saveInstitution(
          currentUser!.institutionId!,
        ); // 👈 add this
      } else {
        print('❌ institution is null, not saving');
      }
      if (currentUser?.programmeId != null) {
        await _authService.saveProgrammeId(currentUser!.programmeId!);
      }
      if (_programmeId != null) {
        print('💾 Saving programmeId: $_programmeId');
        await _authService.saveProgrammeId(_programmeId!);
      } else {
        print('❌ programmeId is null, not saving');
      }

      final syncService = SyncService(authController: this);
      await syncService.syncOnStartup();
      await NotificationService.startBackgroundSync();
      isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      errorMessage = e.toString().replaceFirst('Exception: ', '');
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
    required int institutionId,
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
        institutionId: institutionId,
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
    // The next person to sign in on this device mustn't see these pages,
    // or get this person's study reminders.
    await OfflineCache.clear();
    await NotificationService.rescheduleStudyReminders(const []);
    currentUser = null;
    _token = null;
    _role = null;
    _programmeId = null;
    notifyListeners();
  }
}
