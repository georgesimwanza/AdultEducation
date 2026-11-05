import 'package:flutter/widgets.dart';
import 'package:video_player/video_player.dart';

// The web keeps nothing on the device: videos stream and documents open in
// the browser's own viewer.

const bool canDownload = false;

Future<(String, int)> downloadToDevice(
  String url,
  void Function(int received, int total) onProgress,
) =>
    throw UnsupportedError('Files are not saved in the browser');

Future<bool> fileExists(String path) async => false;

Future<void> deleteFile(String path) async {}

VideoPlayerController videoController(String source, {required bool local}) =>
    VideoPlayerController.networkUrl(Uri.parse(source));

Widget localImage(String path) => const SizedBox.shrink();
