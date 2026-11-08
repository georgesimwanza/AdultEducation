import 'package:adult/core/responsive.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:adult/screens/color.dart';
import 'package:adult/service/media/media_files.dart' as files;
import 'package:adult/service/media/media_store.dart';

class VideoPlayerScreen extends StatefulWidget {
  final String url;
  final String title;

  const VideoPlayerScreen({super.key, required this.url, required this.title});

  @override
  State<VideoPlayerScreen> createState() => _VideoPlayerScreenState();
}

class _VideoPlayerScreenState extends State<VideoPlayerScreen> {
  // Dark surfaces derived from the palette's text colour, so the player
  // feels part of the app while staying easy on the eyes.
  static const Color _bg = Color(0xFF0F1126);
  static const Color _panel = EduColors.ink;

  static const List<double> _speeds = [1.0, 1.25, 1.5, 2.0, 0.75];

  VideoPlayerController? _ctrl;
  VideoPlayerController get _controller => _ctrl!;
  late Future<void> _init;

  /// Playing the copy saved on this device (works offline).
  bool _local = false;

  int _speedIndex = 0;
  bool _muted = false;

  MediaStore get _store => MediaStore.instance;

  @override
  void initState() {
    super.initState();
    _open();
  }

  /// Plays the saved copy if there is one, otherwise streams.
  void _open() {
    final saved = _store.localPath(widget.url);
    _local = saved != null;
    _init = _start(saved);
  }

  Future<void> _start(String? saved) async {
    final c = await files.openVideo(saved ?? widget.url, local: saved != null);
    _ctrl = c;
    await c.initialize();
    // Browsers may block autoplay; the play button still works then.
    c.play().catchError((Object _) {});
  }

  Future<void> _close(VideoPlayerController? c) async {
    if (c == null) return;
    await c.dispose();
    files.releaseSource(c.dataSource);
  }

  Future<void> _retry() async {
    final old = _ctrl;
    _ctrl = null;
    setState(_open);
    await _close(old);
  }

  Future<void> _download() async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      await _store.download(widget.url);
      messenger.showSnackBar(const SnackBar(
        content: Text('Saved on this device. It now plays without internet.'),
      ));
      // Switch to the saved copy if streaming had failed.
      if (mounted && (_ctrl?.value.hasError ?? true)) await _retry();
    } catch (_) {
      messenger.showSnackBar(const SnackBar(
        content: Text("Download failed. Check your internet and try again."),
      ));
    }
  }

  @override
  void dispose() {
    _close(_ctrl);
    super.dispose();
  }

  String _fmt(Duration d) {
    String two(int n) => n.toString().padLeft(2, '0');
    final h = d.inHours;
    final m = d.inMinutes.remainder(60);
    final s = d.inSeconds.remainder(60);
    return h > 0 ? '$h:${two(m)}:${two(s)}' : '${two(m)}:${two(s)}';
  }

  bool get _finished {
    final v = _controller.value;
    return v.duration > Duration.zero && v.position >= v.duration;
  }

  Future<void> _togglePlay() async {
    if (_controller.value.isPlaying) {
      await _controller.pause();
    } else {
      if (_finished) await _controller.seekTo(Duration.zero);
      await _controller.play();
    }
  }

  Future<void> _seekBy(int seconds) async {
    final v = _controller.value;
    var target = v.position + Duration(seconds: seconds);
    if (target < Duration.zero) target = Duration.zero;
    if (target > v.duration) target = v.duration;
    await _controller.seekTo(target);
  }

  Future<void> _cycleSpeed() async {
    final next = (_speedIndex + 1) % _speeds.length;
    await _controller.setPlaybackSpeed(_speeds[next]);
    if (!mounted) return;
    setState(() => _speedIndex = next);
  }

  Future<void> _toggleMute() async {
    final next = !_muted;
    await _controller.setVolume(next ? 0 : 1);
    if (!mounted) return;
    setState(() => _muted = next);
  }

  String get _speedLabel {
    final s = _speeds[_speedIndex];
    return s == s.roundToDouble() ? '${s.toInt()}x' : '${s}x';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: ResponsiveCenter(child: SafeArea(
        child: Column(
          children: [
            _buildTopBar(),
            Expanded(
              child: FutureBuilder<void>(
                future: _init,
                builder: (context, snapshot) {
                  if (snapshot.connectionState != ConnectionState.done) {
                    return const Center(
                      child:
                      CircularProgressIndicator(color: EduColors.primary),
                    );
                  }
                  if (snapshot.hasError) return _buildError(snapshot.error);
                  return _buildPlayer();
                },
              ),
            ),
          ],
        ),
      )),
    );
  }

  // ── Top bar ────────────────────────────────────────────────────────────

  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.maybePop(context),
            child: Container(
              width: 44,
              height: 44,
              decoration: const BoxDecoration(
                color: Color(0x1FFFFFFF),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.arrow_back_rounded,
                  color: EduColors.onPrimary, size: 20),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: EduColors.onPrimary,
                  ),
                ),
                Text(
                  _local ? 'Video lesson · saved on this device' : 'Video lesson',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: EduColors.onPrimaryMuted,
                  ),
                ),
              ],
            ),
          ),
          if (_store.canDownload) _buildDownloadButton(),
        ],
      ),
    );
  }

  /// Save for offline: a progress ring while downloading, a tick once saved.
  Widget _buildDownloadButton() {
    return ListenableBuilder(
      listenable: _store,
      builder: (context, _) {
        final saved = _store.localPath(widget.url) != null;
        final progress = _store.progress(widget.url);
        final Widget icon;
        if (progress != null) {
          icon = SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(
              value: progress == 0 ? null : progress,
              strokeWidth: 2.5,
              color: EduColors.onPrimary,
            ),
          );
        } else {
          icon = Icon(
            saved ? Icons.download_done_rounded : Icons.download_rounded,
            color: EduColors.onPrimary,
            size: 22,
          );
        }
        return Tooltip(
          message: saved
              ? 'Saved on this device'
              : progress != null
                  ? 'Downloading ${(progress * 100).round()}%'
                  : 'Download to watch offline',
          child: GestureDetector(
            onTap: saved || progress != null ? null : _download,
            child: Container(
              width: 44,
              height: 44,
              alignment: Alignment.center,
              decoration: const BoxDecoration(
                color: Color(0x1FFFFFFF),
                shape: BoxShape.circle,
              ),
              child: icon,
            ),
          ),
        );
      },
    );
  }

  // ── Error ──────────────────────────────────────────────────────────────

  Widget _buildError(Object? error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: const Color(0x1FFFFFFF),
                borderRadius: BorderRadius.circular(22),
              ),
              child: const Icon(Icons.videocam_off_rounded,
                  color: EduColors.onPrimary, size: 34),
            ),
            const SizedBox(height: 18),
            Text(
              _local ? "Couldn't play this video" : "Can't reach the video",
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w800,
                color: EduColors.onPrimary,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              _local
                  ? 'The saved file may be damaged. Delete it and download it again.'
                  : _store.canDownload
                      ? 'Streaming needs internet. Connect and try again, or '
                          'download it while online to watch it offline later.'
                      : 'Check your internet connection and try again.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 13,
                height: 1.4,
                color: EduColors.onPrimaryMuted,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              '$error',
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 10, color: Color(0x80FFFFFF)),
            ),
            const SizedBox(height: 18),
            ElevatedButton(
              onPressed: _retry,
              style: ElevatedButton.styleFrom(
                backgroundColor: EduColors.primary,
                foregroundColor: EduColors.onPrimary,
                elevation: 0,
                padding:
                const EdgeInsets.symmetric(horizontal: 26, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              child: const Text('Try again'),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => Navigator.maybePop(context),
              style: TextButton.styleFrom(foregroundColor: EduColors.onPrimaryMuted),
              child: const Text('Go back'),
            ),
          ],
        ),
      ),
    );
  }

  // ── Player ─────────────────────────────────────────────────────────────

  Widget _buildPlayer() {
    return Column(
      children: [
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Center(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: AspectRatio(
                  aspectRatio: _controller.value.aspectRatio == 0
                      ? 16 / 9
                      : _controller.value.aspectRatio,
                  child: GestureDetector(
                    onTap: _togglePlay,
                    child: ValueListenableBuilder<VideoPlayerValue>(
                      valueListenable: _controller,
                      builder: (context, value, _) {
                        return Stack(
                          alignment: Alignment.center,
                          children: [
                            VideoPlayer(_controller),
                            if (value.isBuffering)
                              const CircularProgressIndicator(
                                  color: EduColors.onPrimary),
                            // Big play hint while paused.
                            AnimatedOpacity(
                              duration: const Duration(milliseconds: 200),
                              opacity:
                              (!value.isPlaying && !value.isBuffering)
                                  ? 1
                                  : 0,
                              child: Container(
                                width: 68,
                                height: 68,
                                decoration: const BoxDecoration(
                                  color: Color(0x99000000),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  _finished
                                      ? Icons.replay_rounded
                                      : Icons.play_arrow_rounded,
                                  color: EduColors.onPrimary,
                                  size: 40,
                                ),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        _buildControls(),
      ],
    );
  }

  Widget _buildControls() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
      decoration: const BoxDecoration(
        color: _panel,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: ValueListenableBuilder<VideoPlayerValue>(
        valueListenable: _controller,
        builder: (context, value, _) {
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              VideoProgressIndicator(
                _controller,
                allowScrubbing: true,
                padding: const EdgeInsets.symmetric(vertical: 8),
                colors: const VideoProgressColors(
                  playedColor: EduColors.primary,
                  bufferedColor: Color(0x4DFFFFFF),
                  backgroundColor: Color(0x1FFFFFFF),
                ),
              ),
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _fmt(value.position),
                    style: const TextStyle(
                      color: EduColors.onPrimary,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    _fmt(value.duration),
                    style: const TextStyle(
                      color: EduColors.onPrimaryMuted,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Speed
                  _pillButton(
                    label: _speedLabel,
                    onTap: _cycleSpeed,
                  ),
                  // Back 10s
                  _roundIconButton(
                    icon: Icons.replay_10_rounded,
                    onTap: () => _seekBy(-10),
                  ),
                  // Play / pause
                  GestureDetector(
                    onTap: _togglePlay,
                    child: Container(
                      width: 66,
                      height: 66,
                      decoration: const BoxDecoration(
                        color: EduColors.primary,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Color(0x663D5CFF),
                            blurRadius: 18,
                            offset: Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Icon(
                        value.isPlaying
                            ? Icons.pause_rounded
                            : (_finished
                            ? Icons.replay_rounded
                            : Icons.play_arrow_rounded),
                        color: EduColors.onPrimary,
                        size: 34,
                      ),
                    ),
                  ),
                  // Forward 10s
                  _roundIconButton(
                    icon: Icons.forward_10_rounded,
                    onTap: () => _seekBy(10),
                  ),
                  // Mute
                  _roundIconButton(
                    icon: _muted
                        ? Icons.volume_off_rounded
                        : Icons.volume_up_rounded,
                    onTap: _toggleMute,
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _roundIconButton({required IconData icon, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 46,
        height: 46,
        decoration: const BoxDecoration(
          color: Color(0x1FFFFFFF),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: EduColors.onPrimary, size: 24),
      ),
    );
  }

  Widget _pillButton({required String label, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 46,
        height: 46,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: EduColors.primary.withAlpha(60),
          borderRadius: BorderRadius.circular(23),
          border: Border.all(color: EduColors.primary),
        ),
        child: Text(
          label,
          style: const TextStyle(
            color: EduColors.onPrimary,
            fontSize: 12,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}