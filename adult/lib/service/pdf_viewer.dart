import 'package:flutter/material.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';

class PdfViewerScreen extends StatelessWidget {
  final String path;
  final String title;

  const PdfViewerScreen({super.key, required this.path, required this.title});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title, maxLines: 1, overflow: TextOverflow.ellipsis),
        backgroundColor: const Color(0xFF111111),
        foregroundColor: Colors.white,
      ),
      body: PDFView(
        filePath: path,
        onError: (e) => debugPrint('PDF error: $e'),
        onPageError: (page, e) => debugPrint('PDF page $page error: $e'),
      ),
    );
  }
}