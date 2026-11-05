import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'package:adult/service/api_config.dart';
import 'package:adult/service/offline_cache.dart';

/// JSON headers carrying the signed-in user's token. Every write to the
/// backend needs this: uploads, quizzes, grading and admin actions are
/// rejected without a staff token.
Future<Map<String, String>> authHeaders() async {
  final prefs = await SharedPreferences.getInstance();
  final token = prefs.getString('auth_token');
  return {
    'Content-Type': 'application/json',
    if (token != null) 'Authorization': 'Bearer $token',
  };
}

/// Error with a message that is safe to show the user.
class ApiException implements Exception {
  final int statusCode;
  final String message;
  ApiException(this.statusCode, this.message);

  @override
  String toString() => message;
}

/// Small client for the learning endpoints (profiles, enrollment, progress,
/// assignments, attendance, messages, notifications and reports).
///
/// Works offline: reads come from the copy saved the last time they were
/// loaded (see OfflineCache), and changes are saved on the device and sent
/// after reconnecting, in which case [QueuedOffline] is thrown.
class LmsApi {
  static const String _base = '$kBackendHost/api';
  static const Duration _timeout = Duration(seconds: 20);

  static Future<dynamic> get(String path) => _send('GET', path);
  static Future<dynamic> post(String path, [Object? body]) => _send('POST', path, body);
  static Future<dynamic> put(String path, [Object? body]) => _send('PUT', path, body);
  static Future<dynamic> patch(String path, [Object? body]) => _send('PATCH', path, body);
  static Future<dynamic> delete(String path) => _send('DELETE', path);

  /// Raw text (e.g. CSV exports).
  static Future<String> getText(String path) async {
    final res = await _get(path);
    _check(res);
    return res.body;
  }

  static Future<http.Response> _get(String path) async {
    try {
      return await cachedGet(Uri.parse('$_base$path'),
          headers: await authHeaders(), timeout: _timeout);
    } on NotSavedOffline catch (e) {
      throw ApiException(0, e.toString());
    }
  }

  static String url(String path) => '$_base$path';

  static Future<dynamic> _send(String method, String path, [Object? body]) async {
    if (method == 'GET') {
      final res = await _get(path);
      _check(res);
      if (res.body.isEmpty) return null;
      return jsonDecode(res.body);
    }
    final uri = Uri.parse('$_base$path');
    final headers = await authHeaders();
    final encoded = body == null ? null : jsonEncode(body);
    late http.Response res;
    try {
      if (OfflineCache.isOffline()) throw const QueuedOffline();
      res = await switch (method) {
        'POST' => http.post(uri, headers: headers, body: encoded),
        'PUT' => http.put(uri, headers: headers, body: encoded),
        'PATCH' => http.patch(uri, headers: headers, body: encoded),
        _ => http.delete(uri, headers: headers),
      }.timeout(_timeout);
    } catch (_) {
      // No connection: keep the change and send it after reconnecting.
      await OfflineCache.enqueue(method, uri.toString(), encoded, headers);
      throw const QueuedOffline();
    }
    _check(res);
    if (res.body.isEmpty) return null;
    return jsonDecode(res.body);
  }

  static void _check(http.Response res) {
    if (res.statusCode >= 200 && res.statusCode < 300) return;
    if (res.statusCode == 401) {
      OfflineCache.onUnauthorized?.call();
      throw ApiException(401, 'Your session has expired. Please sign in again.');
    }
    String message;
    try {
      final decoded = jsonDecode(res.body);
      message = decoded is Map && decoded['message'] != null
          ? decoded['message'].toString()
          : res.body;
    } catch (_) {
      message = res.body;
    }
    if (message.trim().isEmpty) {
      message = switch (res.statusCode) {
        401 => 'Please sign in again.',
        403 => 'You do not have permission to do that.',
        404 => 'Not found.',
        _ => 'Something went wrong (${res.statusCode}).',
      };
    }
    throw ApiException(res.statusCode, message);
  }
}
