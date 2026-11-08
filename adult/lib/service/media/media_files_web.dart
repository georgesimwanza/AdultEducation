import 'dart:js_interop';
import 'dart:typed_data';
import 'dart:ui_web' as ui_web;

import 'package:dio/dio.dart';
import 'package:flutter/widgets.dart';
import 'package:video_player/video_player.dart';
import 'package:web/web.dart' as web;

import 'package:adult/service/api_config.dart';
import 'package:adult/service/lms_api.dart';

// Lesson files saved in the browser's Cache Storage, which is made for
// large files, survives restarts and works offline. A saved file's "path"
// is its URL (the cache key); it is shown through an in-memory blob URL.

const bool canDownload = true;

const _cacheName = 'pamodzi-lessons';

Future<web.Cache> _cache() => web.window.caches.open(_cacheName).toDart;

bool _askedToPersist = false;

/// Downloads [url] into browser storage; returns (key, size).
///
/// Goes through the backend's content mirror first (works whenever the
/// server is reachable, even without internet), then the CDN directly.
Future<(String, int)> downloadToDevice(
  String url,
  void Function(int received, int total) onProgress,
) async {
  // Ask the browser not to clear these files when space runs low.
  if (!_askedToPersist) {
    _askedToPersist = true;
    try {
      await web.window.navigator.storage.persist().toDart;
    } catch (_) {}
  }
  final dio = Dio(BaseOptions(
    connectTimeout: const Duration(seconds: 15),
    receiveTimeout: const Duration(minutes: 5),
  ));
  final mirror = Uri.parse('$kBackendHost/api/media/file')
      .replace(queryParameters: {'url': url});
  Response<List<int>> res;
  try {
    res = await dio.getUri<List<int>>(mirror,
        options: Options(responseType: ResponseType.bytes, headers: await authHeaders()),
        onReceiveProgress: onProgress);
  } on DioException {
    res = await dio.get<List<int>>(url,
        options: Options(responseType: ResponseType.bytes), onReceiveProgress: onProgress);
  }
  final bytes = Uint8List.fromList(res.data ?? const []);
  final type = res.headers.value('content-type') ?? 'application/octet-stream';
  final blob = web.Blob(<JSAny>[bytes.toJS].toJS, web.BlobPropertyBag(type: type));
  final cache = await _cache();
  await cache
      .put(
        url.toJS,
        web.Response(blob, web.ResponseInit(headers: {'content-type': type}.jsify() as web.HeadersInit)),
      )
      .toDart;
  return (url, bytes.length);
}

Future<bool> fileExists(String path) async {
  final cache = await _cache();
  return (await cache.match(path.toJS).toDart) != null;
}

Future<void> deleteFile(String path) async {
  final cache = await _cache();
  await cache.delete(path.toJS).toDart;
}

/// An address the browser can display or play for a saved file.
Future<String> playableSource(String path) async {
  final cache = await _cache();
  final res = await cache.match(path.toJS).toDart;
  if (res == null) throw StateError('Not saved: $path');
  final blob = await res.blob().toDart;
  return web.URL.createObjectURL(blob);
}

/// Frees the memory of an address made by [playableSource].
void releaseSource(String src) {
  if (src.startsWith('blob:')) web.URL.revokeObjectURL(src);
}

/// A video player for a saved file ([local]) or a stream.
Future<VideoPlayerController> openVideo(String source, {required bool local}) async =>
    VideoPlayerController.networkUrl(
        Uri.parse(local ? await playableSource(source) : source));

Widget localImage(String path) => const SizedBox.shrink();

final Set<String> _registered = {};

/// The browser's own viewer for [src] (PDF toolbar, zoom, search, print;
/// images too), embedded in the app page.
Widget documentFrame(String src) {
  final viewType = 'document-frame-${src.hashCode}';
  if (_registered.add(viewType)) {
    ui_web.platformViewRegistry.registerViewFactory(viewType, (int _) {
      return web.HTMLIFrameElement()
        ..src = src
        ..style.border = 'none'
        ..style.width = '100%'
        ..style.height = '100%';
    });
  }
  return HtmlElementView(viewType: viewType);
}
