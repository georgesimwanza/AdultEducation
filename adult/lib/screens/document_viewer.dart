import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:adult/screens/color.dart';
import 'package:adult/screens/pdf_viewer.dart';
import 'package:adult/service/media/media_files.dart' as files;
import 'package:adult/service/media/media_store.dart';

/// Opens a document lesson inside the app (phone / desktop).
///
/// The first time, it downloads the file and keeps it on the device, so it
/// opens without internet afterwards. PDFs show in the PDF viewer and
/// images in a zoomable viewer; other formats can be opened in the browser.
/// (On the web, lessons open in the browser's own viewer instead.)
class DocumentViewerScreen extends StatefulWidget {
  final String url;
  final String title;

  const DocumentViewerScreen({super.key, required this.url, required this.title});

  @override
  State<DocumentViewerScreen> createState() => _DocumentViewerScreenState();
}

enum _Kind { pdf, image, other }

class _DocumentViewerScreenState extends State<DocumentViewerScreen> {
  String? _path;
  bool _failed = false;

  MediaStore get _store => MediaStore.instance;

  _Kind get _kind {
    final path = Uri.tryParse(widget.url)?.path.toLowerCase() ?? '';
    if (path.endsWith('.pdf')) return _Kind.pdf;
    if (RegExp(r'\.(png|jpe?g|gif|webp|bmp)$').hasMatch(path)) return _Kind.image;
    return _Kind.other;
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _failed = false);
    try {
      final path = await _store.download(widget.url); // instant if already saved
      if (mounted) setState(() => _path = path);
    } catch (e) {
      debugPrint('Document download failed: $e');
      if (mounted) setState(() => _failed = true);
    }
  }

  Future<void> _openInBrowser() async {
    final ok = await launchUrl(Uri.parse(widget.url), mode: LaunchMode.externalApplication);
    if (!ok && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No app on this phone can open this file.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final path = _path;
    if (path != null && _kind == _Kind.pdf) {
      return PdfViewerScreen(path: path, title: widget.title);
    }
    return Scaffold(
      backgroundColor: path != null && _kind == _Kind.image ? Colors.black : EduColors.background,
      body: SafeArea(
        child: Column(
          children: [
            _topBar(dark: path != null && _kind == _Kind.image),
            Expanded(
              child: path != null
                  ? (_kind == _Kind.image ? _imageViewer(path) : _unsupported())
                  : _failed
                      ? _downloadFailed()
                      : _downloading(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _topBar({required bool dark}) {
    final fg = dark ? EduColors.onPrimary : EduColors.textPrimary;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.maybePop(context),
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: dark ? const Color(0x1FFFFFFF) : EduColors.surface,
                shape: BoxShape.circle,
                border: dark ? null : Border.all(color: EduColors.border),
              ),
              child: Icon(Icons.arrow_back_rounded, color: fg, size: 20),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              widget.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: fg),
            ),
          ),
        ],
      ),
    );
  }

  Widget _downloading() {
    return ListenableBuilder(
      listenable: _store,
      builder: (context, _) {
        final p = _store.progress(widget.url);
        return Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.download_rounded, color: EduColors.primary, size: 40),
                const SizedBox(height: 16),
                const Text(
                  'Saving for offline use…',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: EduColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Only the first time. After this it opens without internet.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 13, color: EduColors.textSecondary),
                ),
                const SizedBox(height: 20),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: p == null || p == 0 ? null : p,
                    minHeight: 8,
                    color: EduColors.primary,
                    backgroundColor: EduColors.primarySoft,
                  ),
                ),
                if (p != null && p > 0) ...[
                  const SizedBox(height: 8),
                  Text('${(p * 100).round()}%',
                      style: const TextStyle(
                          fontWeight: FontWeight.w700, color: EduColors.textSecondary)),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _downloadFailed() {
    return _message(
      icon: Icons.cloud_off_rounded,
      title: "Couldn't download this file",
      body: "It hasn't been saved on this phone yet, and the file server can't "
          'be reached. Connect to the internet and try again.',
      action: ('Try again', _load),
    );
  }

  Widget _unsupported() {
    return _message(
      icon: Icons.insert_drive_file_outlined,
      title: 'This file type opens outside the app',
      body: 'It is saved on this phone, but only PDFs and pictures can be shown '
          'here. You can open it in your browser (needs internet).',
      action: ('Open in browser', _openInBrowser),
    );
  }

  Widget _message({
    required IconData icon,
    required String title,
    required String body,
    required (String, VoidCallback) action,
  }) {
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
                color: EduColors.primarySoft,
                borderRadius: BorderRadius.circular(22),
              ),
              child: Icon(icon, color: EduColors.primary, size: 34),
            ),
            const SizedBox(height: 18),
            Text(title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                    fontSize: 17, fontWeight: FontWeight.w800, color: EduColors.textPrimary)),
            const SizedBox(height: 6),
            Text(body,
                textAlign: TextAlign.center,
                style: const TextStyle(
                    fontSize: 13, height: 1.4, color: EduColors.textSecondary)),
            const SizedBox(height: 18),
            ElevatedButton(
              onPressed: action.$2,
              style: ElevatedButton.styleFrom(
                backgroundColor: EduColors.primary,
                foregroundColor: EduColors.onPrimary,
                elevation: 0,
                padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              ),
              child: Text(action.$1),
            ),
          ],
        ),
      ),
    );
  }

  Widget _imageViewer(String path) {
    return InteractiveViewer(
      minScale: 1,
      maxScale: 5,
      child: Center(child: files.localImage(path)),
    );
  }
}
