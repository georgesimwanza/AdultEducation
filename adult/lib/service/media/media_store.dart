import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:sqflite_common/sqlite_api.dart';

import 'package:adult/service/media/media_files.dart' as files;

/// Lesson files (videos, PDFs, images) saved on the device so they open
/// without internet.
///
/// The record lives in its own table, not in `content`, because sync
/// replaces content rows with the server's copy and would forget the path.
/// On the web nothing is saved: the browser streams from the server.
class MediaStore extends ChangeNotifier {
  MediaStore._();
  static final instance = MediaStore._();

  static const _createSql = '''
    CREATE TABLE IF NOT EXISTS media_downloads (
      url TEXT PRIMARY KEY,
      path TEXT,
      bytes INTEGER,
      downloadedAt INTEGER
    )
  ''';

  Database? _db;
  final Map<String, String> _paths = {};
  final Map<String, double> _progress = {};
  final Map<String, Future<String>> _active = {};

  /// Whether this platform can keep files (false on the web).
  bool get canDownload => files.canDownload;

  Future<void> attach(Database db) async {
    // Every sync re-attaches the same database; reloading would wipe the
    // list while downloads are finishing.
    if (identical(_db, db)) return;
    await db.execute(_createSql);
    _db = db;
    _paths.clear();
    for (final row in await db.query('media_downloads')) {
      final url = row['url'] as String, path = row['path'] as String;
      // The OS may have cleared the file (e.g. "clear storage").
      if (await files.fileExists(path)) {
        _paths[url] = path;
      } else {
        await db.delete('media_downloads', where: 'url = ?', whereArgs: [url]);
      }
    }
    notifyListeners();
  }

  /// Where [url] is saved on this device, or null.
  String? localPath(String url) => _paths[url];

  /// 0–1 while [url] is downloading, null otherwise.
  double? progress(String url) => _progress[url];

  /// Saves [url] on the device and returns the local path. Calling it again
  /// while it is downloading returns the same download.
  Future<String> download(String url) {
    final saved = _paths[url];
    if (saved != null) return Future.value(saved);
    return _active[url] ??= _download(url).whenComplete(() => _active.remove(url));
  }

  Future<String> _download(String url) async {
    _progress[url] = 0;
    notifyListeners();
    var lastPercent = 0;
    try {
      final (path, bytes) = await files.downloadToDevice(url, (received, total) {
        if (total <= 0) return;
        final percent = received * 100 ~/ total;
        if (percent == lastPercent) return; // don't rebuild on every chunk
        lastPercent = percent;
        _progress[url] = received / total;
        notifyListeners();
      });
      await _db?.insert('media_downloads', {
        'url': url,
        'path': path,
        'bytes': bytes,
        'downloadedAt': DateTime.now().millisecondsSinceEpoch,
      }, conflictAlgorithm: ConflictAlgorithm.replace);
      _paths[url] = path;
      return path;
    } finally {
      _progress.remove(url);
      notifyListeners();
    }
  }

  // ── Saving every lesson after a sync ──

  /// Files saved at the same time in a bulk download.
  static const _parallel = 3;

  /// Longest one file may take before the batch moves on without it.
  static const _fileTimeout = Duration(minutes: 20);

  bool _bulkActive = false;
  List<String> _bulkUrls = const [];
  int _bulkFailed = 0;
  int _retries = 0;
  Timer? _retry;

  /// Saving lessons in bulk right now (shown in the "Loading content" banner).
  /// Ends as soon as every file is saved, even if the queue is still
  /// winding down, so the banner can never stay up at 100%.
  bool get bulkActive => _bulkActive && bulkDone < bulkTotal;
  int get bulkTotal => _bulkUrls.length;
  int get bulkFailed => _bulkFailed;

  /// Files of the batch saved so far, counted from what is actually on the
  /// device, so the banner moves with every finished file.
  int get bulkDone => _bulkUrls.where(_paths.containsKey).length;

  /// 0–1 across the whole batch, counting files in progress.
  double get bulkProgress {
    if (_bulkUrls.isEmpty) return 0;
    var sum = 0.0;
    for (final u in _bulkUrls) {
      sum += _paths.containsKey(u) ? 1 : (_progress[u] ?? 0);
    }
    return (sum / _bulkUrls.length).clamp(0.0, 1.0);
  }

  /// Saves every file in [urls] that isn't on the device yet, a few at a
  /// time. A file that fails is skipped; the next sync tries it again.
  Future<void> downloadAll(Iterable<String> urls, {bool isRetry = false}) async {
    if (!canDownload || _bulkActive) return;
    if (!isRetry) _retries = 0;
    _retry?.cancel();
    final todo = urls.where((u) => u.isNotEmpty && !_paths.containsKey(u)).toSet().toList();
    if (todo.isEmpty) return;
    _bulkActive = true;
    _bulkUrls = todo;
    _bulkFailed = 0;
    notifyListeners();
    debugPrint('📦 Saving ${todo.length} lesson files for offline use');
    var next = 0;
    Future<void> worker() async {
      while (next < todo.length) {
        final url = todo[next++];
        try {
          // A transfer that hangs must not hold up the whole batch.
          await download(url).timeout(_fileTimeout);
          debugPrint('📦 Saved $url ($bulkDone/${todo.length})');
        } catch (e) {
          _bulkFailed++;
          debugPrint('📦 Could not save $url: $e');
        }
      }
    }
    try {
      await Future.wait([for (var i = 0; i < _parallel; i++) worker()]);
    } finally {
      // Always cleared, or the banner would stay up forever.
      _bulkActive = false;
      debugPrint('📦 Done: $bulkDone saved, $_bulkFailed failed');
      notifyListeners();
    }
    // Some failed (server busy, connection dropped): try them again shortly
    // instead of waiting for the next sync.
    if (_bulkFailed > 0 && _retries < 5) {
      _retries++;
      _retry = Timer(const Duration(minutes: 1), () => downloadAll(todo, isRetry: true));
    }
  }

  /// Deletes the saved copy of [url].
  Future<void> remove(String url) async {
    final path = _paths.remove(url);
    if (path == null) return;
    await files.deleteFile(path);
    await _db?.delete('media_downloads', where: 'url = ?', whereArgs: [url]);
    notifyListeners();
  }
}
