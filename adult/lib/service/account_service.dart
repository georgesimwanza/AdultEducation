import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:adult/service/api_config.dart';

/// Shown to the user as-is, so every message here is written for them.
class AccountException implements Exception {
  final String message;
  const AccountException(this.message);

  @override
  String toString() => message;
}

/// Self-service account changes for the signed-in user.
///
/// Save as: lib/service/account_service.dart
class AccountService {
  AccountService({this.baseUrl = '$kBackendHost/api/account'});

  /// 10.0.2.2 only works from the Android emulator — use your real backend
  /// URL on a physical device or in production (same as the other services).
  final String baseUrl;

  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token') ?? '';

    final http.Response response;
    try {
      response = await http
          .put(
        Uri.parse('$baseUrl/password'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'currentPassword': currentPassword,
          'newPassword': newPassword,
        }),
      )
          .timeout(const Duration(seconds: 15));
    } catch (_) {
      throw const AccountException(
        'Could not reach the server. Connect to the internet and try again.',
      );
    }

    if (response.statusCode == 200 || response.statusCode == 204) return;

    if (response.statusCode == 400 && response.body.trim().isNotEmpty) {
      // The backend sends a readable reason, e.g. "Current password is incorrect".
      throw AccountException(response.body.trim());
    }
    if (response.statusCode == 401 || response.statusCode == 403) {
      throw const AccountException(
        'Your session has expired. Please sign in again.',
      );
    }
    throw AccountException(
      'Something went wrong (${response.statusCode}). Please try again.',
    );
  }
}