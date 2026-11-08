import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/widgets.dart';
import 'package:path_provider/path_provider.dart';
import 'package:video_player/video_player.dart';

import 'package:adult/service/api_config.dart';
import 'package:adult/service/lms_api.dart';

// Lesson files saved in the app's private storage (removed with the app).

const bool canDownload = true;

/// Downloads [url] into the app's media folder; returns (path, size).
///
/// Goes through the backend's content mirror (/api/media/file) first: it
/// works whenever the app can reach the server, even with no internet (the
/// school network, or USB). If the mirror fails, it tries the CDN directly.
/// Writes to a ".part" file first so a dropped connection never leaves a
/// half file that looks complete.
Future<(String, int)> downloadToDevice(
  String url,
  void Function(int received, int total) onProgress,
) async {
  final dir = Directory('${(await getApplicationSupportDirectory()).path}/media');
  await dir.create(recursive: true);
  final target = File('${dir.path}/${_fileName(url)}');
  final part = File('${target.path}.part');
  // receiveTimeout: give up when no data arrives for a minute, so a dead
  // connection can't stall the download queue forever.
  final dio = Dio(BaseOptions(
    connectTimeout: const Duration(seconds: 15),
    receiveTimeout: const Duration(seconds: 60),
  ));
  final mirror = Uri.parse('$kBackendHost/api/media/file')
      .replace(queryParameters: {'url': url});
  try {
    try {
      // The server may still be fetching the file from the CDN before it
      // sends anything, so allow a longer quiet period here.
      await dio.downloadUri(mirror, part.path,
          onReceiveProgress: onProgress,
          options: Options(
            headers: await authHeaders(),
            receiveTimeout: const Duration(minutes: 5),
          ));
    } on DioException {
      await dio.download(url, part.path, onReceiveProgress: onProgress);
    }
  } catch (_) {
    if (await part.exists()) await part.delete();
    rethrow;
  }
  if (await target.exists()) await target.delete();
  await part.rename(target.path);
  return (target.path, await target.length());
}

Future<bool> fileExists(String path) => File(path).exists();

Future<void> deleteFile(String path) async {
  final f = File(path);
  if (await f.exists()) await f.delete();
}

/// A video player for a saved file ([local]) or a stream.
Future<VideoPlayerController> openVideo(String source, {required bool local}) async =>
    local
        ? VideoPlayerController.file(File(source))
        : VideoPlayerController.networkUrl(Uri.parse(source));

Widget localImage(String path) => Image.file(File(path), fit: BoxFit.contain);

// Saved files are shown straight from their path here.
Future<String> playableSource(String path) async => path;
void releaseSource(String src) {}

/// Web only (embedded browser viewer); documents use PdfViewerScreen here.
Widget documentFrame(String src) => const SizedBox.shrink();

/// A stable, unique file name: the original name plus a hash of the URL
/// (two courses can have files with the same name).
String _fileName(String url) {
  final uri = Uri.parse(url);
  final original = Uri.decodeComponent(
      uri.pathSegments.isEmpty ? 'file' : uri.pathSegments.last);
  final safe = original.replaceAll(RegExp(r'[^\w.\-]'), '_');
  var hash = 0x811c9dc5; // FNV-1a
  for (final c in url.codeUnits) {
    hash = ((hash ^ c) * 0x01000193) & 0xffffffff;
  }
  return '${hash.toRadixString(16)}_$safe';
}
