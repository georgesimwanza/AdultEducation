import 'package:adult/screens/color.dart';
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:adult/core/responsive.dart';
import 'package:adult/service/connectivity_service.dart';
import 'package:adult/service/media/media_store.dart';

/// Slim bar above every screen showing whether the app is online, syncing
/// after reconnecting, or offline and working from data saved on the device.
class ConnectionStatusBar extends StatelessWidget {
  const ConnectionStatusBar({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final connectivity = context.watch<ConnectivityService>();
    final status = connectivity.status;
    return Stack(
      children: [
        Column(
          children: [
            _Bar(status: status, awaitingSync: connectivity.awaitingConsent),
            const _ContentDownloadBar(),
            Expanded(
              child: MediaQuery.removePadding(
                context: context,
                removeTop: true,
                child: child,
              ),
            ),
          ],
        ),
        const _UpdateCheckToast(),
        const _SyncPopup(),
        const _AskToSyncPopup(),
      ],
    );
  }
}

/// Pop-up shown when the server comes back: it says what is being synced,
/// then confirms when everything is up to date and closes by itself.
class _SyncPopup extends StatefulWidget {
  const _SyncPopup();

  @override
  State<_SyncPopup> createState() => _SyncPopupState();
}

enum _PopupState { hidden, syncing, done, failed }

class _SyncPopupState extends State<_SyncPopup> {
  _PopupState _state = _PopupState.hidden;
  ConnectionStatus? _last;
  ConnectivityService? _connectivity;
  Timer? _hideTimer;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final c = context.read<ConnectivityService>();
    if (c == _connectivity) return;
    _connectivity?.removeListener(_onChange);
    _connectivity = c..addListener(_onChange);
    _last = c.status;
  }

  void _onChange() {
    final c = _connectivity!;
    final status = c.status;
    if (status == ConnectionStatus.syncing &&
        _last != ConnectionStatus.syncing) {
      _hideTimer?.cancel();
      setState(() => _state = _PopupState.syncing);
    } else if (_last == ConnectionStatus.syncing &&
        status != ConnectionStatus.syncing) {
      // Still open: report how it went, then close. (If the learner hid it,
      // leave it hidden.)
      if (_state == _PopupState.syncing) {
        final ok = status == ConnectionStatus.online && c.lastSyncOk;
        setState(() => _state = ok ? _PopupState.done : _PopupState.failed);
        _hideTimer = Timer(const Duration(seconds: 2), _hide);
      }
    } else if (_state == _PopupState.syncing) {
      setState(() {}); // new stage text
    }
    _last = status;
  }

  void _hide() {
    _hideTimer?.cancel();
    if (mounted) setState(() => _state = _PopupState.hidden);
  }

  @override
  void dispose() {
    _hideTimer?.cancel();
    _connectivity?.removeListener(_onChange);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_state == _PopupState.hidden) return const SizedBox.shrink();
    final stage = _connectivity?.syncStage ?? '';
    final (Widget icon, String title, String message) = switch (_state) {
      _PopupState.syncing => (
        const SizedBox(
          width: 44,
          height: 44,
          child: CircularProgressIndicator(
            strokeWidth: 4,
            color: Color(0xFF16A34A),
          ),
        ),
        'Server is back — syncing',
        stage.isEmpty ? 'Updating your data...' : stage,
      ),
      _PopupState.done => (
        const Icon(
          Icons.check_circle_rounded,
          size: 52,
          color: Color(0xFF16A34A),
        ),
        'All synced',
        'Your changes were sent and everything is up to date.',
      ),
      _ => (
        const Icon(Icons.cloud_off_rounded, size: 52, color: Color(0xFFDC2626)),
        'Sync stopped',
        'The connection dropped. It will try again when you are back online.',
      ),
    };

    return Positioned.fill(
      child: Material(
        color: Colors.black45,
        child: Center(
          child: Semantics(
            liveRegion: true,
            label: '$title. $message',
            child: Container(
              width: 340,
              margin: const EdgeInsets.all(24),
              padding: const EdgeInsets.fromLTRB(24, 28, 24, 16),
              decoration: BoxDecoration(
                color: EduColors.surface,
                borderRadius: BorderRadius.circular(20),
                boxShadow: const [
                  BoxShadow(color: Colors.black26, blurRadius: 24),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  icon,
                  const SizedBox(height: 18),
                  Text(
                    title,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 19,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 8),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 200),
                    child: Text(
                      message,
                      key: ValueKey(message),
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 15,
                        color: EduColors.textSecondary,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: _hide,
                    child: Text(
                      _state == _PopupState.syncing
                          ? 'Continue in background'
                          : 'Close',
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Bar extends StatelessWidget {
  const _Bar({required this.status, this.awaitingSync = false});

  final ConnectionStatus status;

  /// Back online but the user hasn't agreed to sync yet: tap to sync.
  final bool awaitingSync;

  @override
  Widget build(BuildContext context) {
    final short = context.isMobile;
    final (Color bg, Color fg, Widget icon, String text) = switch (status) {
      ConnectionStatus.online => (
        const Color(0xFFE7F7EE),
        const Color(0xFF15803D),
        const _Dot(color: Color(0xFF22C55E)),
        awaitingSync ? 'Online · tap to sync new information' : 'Online',
      ),
      ConnectionStatus.syncing => (
        const Color(0xFF16A34A),
        Colors.white,
        const SizedBox(
          width: 12,
          height: 12,
          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
        ),
        short
            ? 'Back online · syncing…'
            : 'Back online — syncing your changes…',
      ),
      ConnectionStatus.offline => (
        const Color(0xFF1F2937),
        Colors.white,
        const Icon(Icons.cloud_off_rounded, size: 15, color: Color(0xFFFBBF24)),
        short
            ? 'Offline · using saved data'
            : 'Offline mode — showing data saved on this device. Changes will sync when you reconnect.',
      ),
    };

    final tappable = awaitingSync && status == ConnectionStatus.online;
    return Semantics(
      liveRegion: true,
      label: text,
      button: tappable,
      child: GestureDetector(
        onTap: tappable
            ? () => context.read<ConnectivityService>().syncNow()
            : null,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          width: double.infinity,
          color: bg,
          padding: EdgeInsets.only(
            top: MediaQuery.paddingOf(context).top + 5,
            bottom: 5,
            left: 12,
            right: 12,
          ),
          child: Material(
            type: MaterialType.transparency,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                icon,
                const SizedBox(width: 8),
                Flexible(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 200),
                    child: Text(
                      text,
                      key: ValueKey(text),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: fg,
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Dot extends StatelessWidget {
  const _Dot({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 8,
      height: 8,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}

/// "Loading content" banner while lessons are saved on the phone for offline
/// use, then a short confirmation once they are all saved.
class _ContentDownloadBar extends StatefulWidget {
  const _ContentDownloadBar();

  @override
  State<_ContentDownloadBar> createState() => _ContentDownloadBarState();
}

class _ContentDownloadBarState extends State<_ContentDownloadBar> {
  final _store = MediaStore.instance;
  bool _wasActive = false;
  bool _showDone = false;
  Timer? _hide;

  @override
  void initState() {
    super.initState();
    _store.addListener(_onChange);
  }

  void _onChange() {
    final active = _store.bulkActive;
    if (_wasActive && !active) {
      // Batch finished: confirm briefly.
      _showDone = true;
      _hide?.cancel();
      _hide = Timer(const Duration(seconds: 4), () {
        if (mounted) setState(() => _showDone = false);
      });
    }
    if (active) _showDone = false;
    _wasActive = active;
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _hide?.cancel();
    _store.removeListener(_onChange);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final active = _store.bulkActive;
    if (!active && !_showDone) return const SizedBox.shrink();
    final failed = _store.bulkFailed;
    final String text;
    if (active) {
      text =
          'Loading content for offline use… '
          '${_store.bulkDone} of ${_store.bulkTotal} saved';
    } else if (failed > 0) {
      text =
          '$failed file${failed == 1 ? '' : 's'} could not be saved. '
          'Will try again when online.';
    } else {
      text = 'All lessons saved. They now open without internet.';
    }
    final bg = active
        ? const Color(0xFF3D5CFF)
        : failed > 0
        ? const Color(0xFFB45309)
        : const Color(0xFF15803D);
    return Semantics(
      liveRegion: true,
      label: text,
      child: Material(
        color: bg,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 7, 14, 7),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Icon(
                    active
                        ? Icons.downloading_rounded
                        : failed > 0
                        ? Icons.error_outline_rounded
                        : Icons.download_done_rounded,
                    size: 16,
                    color: Colors.white,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      text,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  if (active)
                    Text(
                      '${(_store.bulkProgress * 100).round()}%',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12.5,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                ],
              ),
              if (active) ...[
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: _store.bulkProgress,
                    minHeight: 4,
                    color: Colors.white,
                    backgroundColor: const Color(0x40FFFFFF),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Small card in the top corner while the app quietly checks for new
/// information, then the result for a few seconds.
class _UpdateCheckToast extends StatefulWidget {
  const _UpdateCheckToast();

  @override
  State<_UpdateCheckToast> createState() => _UpdateCheckToastState();
}

class _UpdateCheckToastState extends State<_UpdateCheckToast> {
  ConnectivityService? _connectivity;
  bool _wasChecking = false;
  bool _showResult = false;
  Timer? _hide;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final c = context.read<ConnectivityService>();
    if (c == _connectivity) return;
    _connectivity?.removeListener(_onChange);
    _connectivity = c..addListener(_onChange);
  }

  void _onChange() {
    final checking = _connectivity!.checkingForUpdates;
    if (_wasChecking && !checking) {
      _showResult = true;
      _hide?.cancel();
      _hide = Timer(const Duration(seconds: 3), () {
        if (mounted) setState(() => _showResult = false);
      });
    }
    if (checking) _showResult = false;
    _wasChecking = checking;
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _hide?.cancel();
    _connectivity?.removeListener(_onChange);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = _connectivity;
    final checking = c?.checkingForUpdates ?? false;
    final visible = checking || _showResult;
    final found = c?.lastCheckNewItems;
    final Widget icon;
    final String text;
    if (checking) {
      icon = const SizedBox(
        width: 14,
        height: 14,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          color: Color(0xFF3D5CFF),
        ),
      );
      text = 'Checking for new information…';
    } else if (found == null) {
      icon = const Icon(
        Icons.cloud_off_rounded,
        size: 16,
        color: Color(0xFFB45309),
      );
      text = "Couldn't check right now";
    } else if (found == 0) {
      icon = const Icon(
        Icons.check_circle_rounded,
        size: 16,
        color: Color(0xFF15803D),
      );
      text = "You're up to date";
    } else {
      icon = const Icon(
        Icons.fiber_new_rounded,
        size: 18,
        color: Color(0xFF3D5CFF),
      );
      text = '$found new update${found == 1 ? '' : 's'} downloaded';
    }
    return Positioned(
      top: MediaQuery.paddingOf(context).top + 40,
      right: 12,
      child: IgnorePointer(
        ignoring: !visible,
        child: AnimatedSlide(
          duration: const Duration(milliseconds: 250),
          offset: visible ? Offset.zero : const Offset(0.3, 0),
          child: AnimatedOpacity(
            duration: const Duration(milliseconds: 250),
            opacity: visible ? 1 : 0,
            child: Semantics(
              liveRegion: true,
              label: text,
              child: Material(
                color: EduColors.surface,
                elevation: 6,
                shadowColor: Colors.black26,
                borderRadius: BorderRadius.circular(14),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      icon,
                      const SizedBox(width: 10),
                      Text(
                        text,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: EduColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Phone, back online: "Do you want to sync new information now?"
class _AskToSyncPopup extends StatelessWidget {
  const _AskToSyncPopup();

  @override
  Widget build(BuildContext context) {
    final c = context.watch<ConnectivityService>();
    if (!c.awaitingConsent ||
        c.consentDismissed ||
        c.status != ConnectionStatus.online) {
      return const SizedBox.shrink();
    }
    return Positioned.fill(
      child: Material(
        color: Colors.black45,
        child: Center(
          child: Container(
            width: 340,
            margin: const EdgeInsets.all(24),
            padding: const EdgeInsets.fromLTRB(24, 28, 24, 16),
            decoration: BoxDecoration(
              color: EduColors.surface,
              borderRadius: BorderRadius.circular(20),
              boxShadow: const [
                BoxShadow(color: Colors.black26, blurRadius: 24),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.wifi_rounded,
                  size: 52,
                  color: Color(0xFF16A34A),
                ),
                const SizedBox(height: 18),
                const Text(
                  "You're back online",
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 19, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 8),
                Text(
                  'Do you want to sync new information now? Changes you made '
                  'offline will be sent and new lessons downloaded.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 15, color: EduColors.textSecondary),
                ),
                const SizedBox(height: 18),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: c.syncNow,
                    icon: const Icon(Icons.sync_rounded),
                    label: const Text('Sync now'),
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF16A34A),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),
                TextButton(
                  onPressed: c.dismissConsent,
                  child: const Text('Later'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
