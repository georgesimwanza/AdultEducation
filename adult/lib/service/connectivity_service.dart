import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:adult/service/platform/network_events.dart';

import 'package:adult/service/api_config.dart';

enum ConnectionStatus {
  /// Server reachable.
  online,

  /// Just came back online and is uploading saved changes.
  syncing,

  /// No network, or the server can't be reached: the app works from the
  /// data stored on this device.
  offline,
}

/// Tracks whether the app can reach the PAMODZI server.
///
/// The browser's `online` / `offline` events give an instant signal when the
/// network drops or returns; a small request to the API confirms the server
/// itself answers (Wi-Fi can be up while the server is down). A periodic
/// check catches server outages and recoveries the browser can't see.
class ConnectivityService extends ChangeNotifier {
  ConnectivityService({this.onReconnect});

  /// Runs each time the app goes from offline to online, e.g. to upload
  /// changes saved locally and refresh the cache. It reports what it is
  /// doing through the given callback, shown in the sync pop-up.
  final Future<void> Function(void Function(String stage) report)? onReconnect;

  static const _checkEvery = Duration(seconds: 15);
  static const _pingTimeout = Duration(seconds: 5);

  ConnectionStatus _status = ConnectionStatus.online;
  ConnectionStatus get status => _status;
  bool get isOnline => _status != ConnectionStatus.offline;

  /// What the sync after reconnecting is doing right now.
  String _syncStage = '';
  String get syncStage => _syncStage;

  /// Whether the last sync after reconnecting finished without errors.
  bool _lastSyncOk = true;
  bool get lastSyncOk => _lastSyncOk;

  StreamSubscription<bool>? _networkSub;
  Timer? _timer;
  bool _checking = false;

  /// Starts listening; resolves once the first check is done so the app
  /// starts in the right mode.
  Future<void> start() async {
    _networkSub = networkChanges()
        .listen((up) => up ? checkNow() : _setOnline(false));
    _timer = Timer.periodic(_checkEvery, (_) => checkNow());
    await checkNow();
  }

  /// Checks right away whether the server can be reached.
  Future<void> checkNow() async {
    if (_checking) return;
    _checking = true;
    try {
      if (!deviceOnline) {
        _setOnline(false);
        return;
      }
      _setOnline(await _serverReachable());
    } finally {
      _checking = false;
    }
  }

  Future<bool> _serverReachable() async {
    try {
      // Any HTTP answer (even 401/403) means the server is up. GET, not
      // HEAD: the backend's CORS rules don't list HEAD, and a CORS-blocked
      // request looks exactly like a network failure in the browser.
      await http
          .get(Uri.parse('$kBackendHost/api/programmes/allProgrammes'))
          .timeout(_pingTimeout);
      return true;
    } catch (_) {
      return false;
    }
  }

  void _setOnline(bool online) {
    if (online == isOnline) return;
    if (!online) {
      _status = ConnectionStatus.offline;
      notifyListeners();
      return;
    }
    _status = ConnectionStatus.syncing;
    notifyListeners();
    _syncAfterReconnect();
  }

  Future<void> _syncAfterReconnect() async {
    _syncStage = 'Connecting to the server...';
    try {
      await onReconnect?.call((stage) {
        _syncStage = stage;
        notifyListeners();
      });
      _lastSyncOk = true;
    } catch (e) {
      debugPrint('Sync after reconnect failed: $e');
      _lastSyncOk = false;
    }
    // Only settle to "online" if the connection didn't drop meanwhile.
    if (_status == ConnectionStatus.syncing) {
      _status = ConnectionStatus.online;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _networkSub?.cancel();
    _timer?.cancel();
    super.dispose();
  }
}
