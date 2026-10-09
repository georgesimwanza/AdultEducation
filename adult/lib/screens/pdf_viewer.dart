import 'package:flutter/material.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:adult/screens/color.dart';

class PdfViewerScreen extends StatefulWidget {
  final String path;
  final String title;

  const PdfViewerScreen({super.key, required this.path, required this.title});

  @override
  State<PdfViewerScreen> createState() => _PdfViewerScreenState();
}

class _PdfViewerScreenState extends State<PdfViewerScreen> {
  bool _isRendered = false;
  String? _error;
  int _currentPage = 0; // zero-based
  int _totalPages = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: EduColors.background,
      body: SafeArea(
        child: Column(
          children: [
            _buildTopBar(),
            const SizedBox(height: 12),
            Expanded(child: _buildViewer()),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.maybePop(context),
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: EduColors.surface,
                shape: BoxShape.circle,
                border: Border.all(color: EduColors.border),
              ),
              child: const Icon(Icons.arrow_back_rounded,
                  color: EduColors.textPrimary, size: 20),
            ),
          ),
          const SizedBox(width: 14),
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: EduColors.accentSoft,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.picture_as_pdf_rounded,
                color: EduColors.accent, size: 22),
          ),
          const SizedBox(width: 12),
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
                    color: EduColors.textPrimary,
                  ),
                ),
                Text(
                  _totalPages > 0
                      ? '$_totalPages ${_totalPages == 1 ? 'page' : 'pages'}'
                      : 'PDF document',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: EduColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildViewer() {
    if (_error != null) {
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
                child: const Icon(Icons.description_outlined,
                    color: EduColors.primary, size: 34),
              ),
              const SizedBox(height: 18),
              const Text(
                "Couldn't open this PDF",
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  color: EduColors.textPrimary,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'The file may be missing or damaged. Go back and try opening it again.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  height: 1.4,
                  color: EduColors.textSecondary,
                ),
              ),
              const SizedBox(height: 18),
              ElevatedButton(
                onPressed: () => Navigator.maybePop(context),
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
                child: const Text('Go back'),
              ),
            ],
          ),
        ),
      );
    }

    return Stack(
      children: [
        // The document sits in a rounded card so it feels part of the app.
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(22),
            child: Container(
              color: EduColors.surface,
              child: PDFView(
                filePath: widget.path,
                enableSwipe: true,
                swipeHorizontal: false,
                autoSpacing: true,
                pageFling: true,
                onRender: (pages) {
                  if (!mounted) return;
                  setState(() {
                    _totalPages = pages ?? 0;
                    _isRendered = true;
                  });
                },
                onPageChanged: (page, total) {
                  if (!mounted) return;
                  setState(() {
                    _currentPage = page ?? 0;
                    _totalPages = total ?? _totalPages;
                  });
                },
                onError: (e) {
                  debugPrint('PDF error: $e');
                  if (!mounted) return;
                  setState(() => _error = '$e');
                },
                onPageError: (page, e) =>
                    debugPrint('PDF page $page error: $e'),
              ),
            ),
          ),
        ),

        // Loading overlay until the first render completes.
        if (!_isRendered)
          const Positioned.fill(
            child: Center(
              child: CircularProgressIndicator(color: EduColors.primary),
            ),
          ),

        // Floating page indicator.
        if (_isRendered && _totalPages > 0)
          Positioned(
            bottom: 28,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xE01B1D3A),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x33000000),
                      blurRadius: 12,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: Text(
                  'Page ${_currentPage + 1} of $_totalPages',
                  style: const TextStyle(
                    color: EduColors.onPrimary,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}