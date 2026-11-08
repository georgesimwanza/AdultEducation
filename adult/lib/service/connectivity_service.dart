import 'dart:async';

import 'package:flutter/widgets.dart';
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
class ConnectivityService extends ChangeNotifier with WidgetsBindingObserver {
  ConnectivityService({this.onSync, this.askBeforeSync = false, this.onAskToSync});

  /// Uploads changes saved locally and downloads what is new; returns how
  /// many new items it found. It reports what it is doing through the given
  /// callback, shown in the sync pop-up.
  final Future<int> Function(void Function(String stage) report)? onSync;

  /// Phone: when the connection comes back, ask before syncing (pop-up and
  /// system notification) instead of starting straight away.
  final bool askBeforeSync;

  /// Called when the connection comes back and [askBeforeSync] is on, e.g.
  /// to post the "sync new information?" notification.
  final void Function()? onAskToSync;

  static const _checkEvery = Duration(seconds: 15);
  static const _pingTimeout = Duration(seconds: 5);

  /// While online, look for new information this often.
  static const _updateEvery = Duration(minutes: 5);

  ConnectionStatus _status = ConnectionStatus.online;
  ConnectionStatus get status => _status;
  bool get isOnline => _status != ConnectionStatus.offline;

  /// What the sync after reconnecting is doing right now.
  String _syncStage = '';
  String get syncStage => _syncStage;

  /// Whether the last sync after reconnecting finished without errors.
  bool _lastSyncOk = true;
  bool get lastSyncOk => _lastSyncOk;

  /// Back online and waiting for the user to agree to sync (phone).
  bool _awaitingConsent = false;
  bool get awaitingConsent => _awaitingConsent;

  /// The user chose "Later": keep waiting, but stop showing the pop-up.
  bool _consentDismissed = false;
  bool get consentDismissed => _consentDismissed;

  /// A quiet check for new information is running (corner pop-up).
  bool _checkingForUpdates = false;
  bool get checkingForUpdates => _checkingForUpdates;

  /// New items found by the last check, or null if it failed.
  int? _lastCheckNewItems;
  int? get lastCheckNewItems => _lastCheckNewItems;

  StreamSubscription<bool>? _networkSub;
  Timer? _timer;
  Timer? _updateTimer;
  bool _checking = false;

  /// Starts listening; resolves once the first check is done so the app
  /// starts in the right mode.
  Future<void> start() async {
    _networkSub = networkChanges()
        .listen((up) => up ? checkNow() : _setOnline(false));
    _timer = Timer.periodic(_checkEvery, (_) => checkNow());
    _updateTimer = Timer.periodic(_updateEvery, (_) => checkForUpdates());
    WidgetsBinding.instance.addObserver(this);
    await checkNow();
  }

  /// Back in the app after using another one: look for anything new.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) checkForUpdates();
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
      _awaitingConsent = false;
      notifyListeners();
      return;
    }
    if (askBeforeSync) {
      _status = ConnectionStatus.online;
      _awaitingConsent = true;
      _consentDismissed = false;
      notifyListeners();
      onAskToSync?.call();
      return;
    }
    _syncAfterReconnect();
  }

  /// Syncs now, with the progress pop-up (e.g. "Sync now" was tapped).
  Future<void> syncNow() async {
    if (_status != ConnectionStatus.online) return;
    _awaitingConsent = false;
    await _syncAfterReconnect();
  }

  /// "Later": stop showing the question; the status bar still offers it.
  void dismissConsent() {
    _consentDismissed = true;
    notifyListeners();
  }

  Future<void> _syncAfterReconnect() async {
    _status = ConnectionStatus.syncing;
    _syncStage = 'Connecting to the server...';
    notifyListeners();
    try {
      await onSync?.call((stage) {
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

  /// Quietly looks for new information while online (no big pop-up, just
  /// the small one in the corner). Skipped while waiting for the user's OK.
  Future<void> checkForUpdates() async {
    if (_status != ConnectionStatus.online || _awaitingConsent || _checkingForUpdates) {
      return;
    }
    _checkingForUpdates = true;
    notifyListeners();
    try {
      _lastCheckNewItems = await onSync?.call((_) {}) ?? 0;
    } catch (e) {
      debugPrint('Update check failed: $e');
      _lastCheckNewItems = null;
    }
    _checkingForUpdates = false;
    notifyListeners();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _networkSub?.cancel();
    _timer?.cancel();
    _updateTimer?.cancel();
    super.dispose();
  }
}
