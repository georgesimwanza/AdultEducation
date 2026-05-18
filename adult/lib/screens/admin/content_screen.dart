import 'package:flutter/material.dart';
import 'package:adult/service/api_service.dart'; // ← import your ApiService

enum ContentType { video, document, image, assignment }

class ContentItem {
  final String id;
  final String title;
  final ContentType type;
  final String subject;
  final DateTime uploadDate;
  final String size;
  final int views;

  ContentItem({
    required this.id,
    required this.title,
    required this.type,
    required this.subject,
    required this.uploadDate,
    required this.size,
    required this.views,
  });

  static ContentType _parseType(String t) {
    switch (t.toLowerCase()) {
      case 'video':
        return ContentType.video;
      case 'image':
        return ContentType.image;
      case 'assignment':
        return ContentType.assignment;
      default:
        return ContentType.document;
    }
  }

  factory ContentItem.fromJson(Map<String, dynamic> json) {
    return ContentItem(
      id: json['id'].toString(),
      title: json['title'] ?? '',
      type: _parseType(json['type'] ?? ''),
      subject: 'Course ${json['courseId'] ?? ''}',
      uploadDate: DateTime.now(),
      size: '—',
      views: 0,
    );
  }
}

class ContentScreen extends StatefulWidget {
  const ContentScreen({super.key});

  @override
  State<ContentScreen> createState() => _ContentScreenState();
}

class _ContentScreenState extends State<ContentScreen> {
  String _searchTerm = '';
  String _filterType = 'all';
  List<ContentItem> _content = [];
  bool _loading = false;
  int _activeCourseId = 0;

  // ── GET via ApiService ──────────────────────────────────────────────────────
  Future<void> _fetchContent() async {
    if (_activeCourseId == 0) return;
    setState(() => _loading = true);
    try {
      final data = await ApiService.getContentByCourseId(_activeCourseId);
      setState(() {
        _content = data.map((j) => ContentItem.fromJson(j)).toList();
      });
    } catch (e) {
      _showError(e.toString());
    } finally {
      setState(() => _loading = false);
    }
  }

  // ── POST via ApiService ─────────────────────────────────────────────────────
  Future<void> _addContent(
    String title,
    ContentType type,
    String subject,
    String courseIdText,
  ) async {
    final courseId = int.tryParse(courseIdText);
    if (courseId == null) {
      _showError('Course ID must be a valid number');
      return;
    }

    try {
      await ApiService.addContent(
        title: title,
        type: type.name,
        fileUrl: '',
        courseId: courseId, // ← from input field
      );
      setState(() => _activeCourseId = courseId); // ← save for _fetchContent
      await _fetchContent();
    } catch (e) {
      _showError(e.toString());
    }
  }

  void _showError(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  List<ContentItem> get _filtered => _content.where((item) {
    final matchSearch =
        item.title.toLowerCase().contains(_searchTerm.toLowerCase()) ||
        item.subject.toLowerCase().contains(_searchTerm.toLowerCase());
    final matchFilter = _filterType == 'all' || item.type.name == _filterType;
    return matchSearch && matchFilter;
  }).toList();

  IconData _getIcon(ContentType t) {
    switch (t) {
      case ContentType.video:
        return Icons.play_circle_outline;
      case ContentType.document:
        return Icons.description_outlined;
      case ContentType.image:
        return Icons.image_outlined;
      case ContentType.assignment:
        return Icons.assignment_outlined;
    }
  }

  Color _getColor(ContentType t) {
    switch (t) {
      case ContentType.video:
        return const Color(0xFFEF4444);
      case ContentType.document:
        return const Color(0xFF3B82F6);
      case ContentType.image:
        return const Color(0xFF22C55E);
      case ContentType.assignment:
        return const Color(0xFFDE782E);
    }
  }

  // ── Add modal ───────────────────────────────────────────────────────────────
  void _showAddModal() {
    final titleCtrl = TextEditingController();
    final subjectCtrl = TextEditingController();
    final courseIdCtrl = TextEditingController();
    ContentType selectedType = ContentType.document;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => DraggableScrollableSheet(
          initialChildSize: 0.7,
          minChildSize: 0.4,
          maxChildSize: 0.95,
          expand: false,
          builder: (_, scrollController) => Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Column(
              children: [
                Container(
                  margin: const EdgeInsets.only(top: 12, bottom: 8),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE5E7EB),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    controller: scrollController,
                    padding: EdgeInsets.only(
                      left: 24,
                      right: 24,
                      bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Add New Content',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF111827),
                              ),
                            ),
                            IconButton(
                              onPressed: () => Navigator.pop(ctx),
                              icon: const Icon(
                                Icons.close,
                                color: Color(0xFF9CA3AF),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // Course ID — numeric keyboard
                        _buildField(
                          courseIdCtrl,
                          'Course ID',
                          'Enter course ID',
                          keyboardType: TextInputType.number,
                        ),
                        const SizedBox(height: 12),

                        // Title
                        _buildField(
                          titleCtrl,
                          'Content Title',
                          'Enter content title',
                        ),
                        const SizedBox(height: 12),

                        // Type dropdown
                        const Text(
                          'Content Type',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF374151),
                          ),
                        ),
                        const SizedBox(height: 6),
                        DropdownButtonFormField<ContentType>(
                          value: selectedType,
                          onChanged: (v) =>
                              setModalState(() => selectedType = v!),
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: const Color(0xFFF9FAFB),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(
                                color: Color(0xFFE5E7EB),
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(
                                color: Color(0xFFE5E7EB),
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(
                                color: Colors.black,
                                width: 2,
                              ),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 4,
                            ),
                          ),
                          items: ContentType.values
                              .map(
                                (t) => DropdownMenuItem(
                                  value: t,
                                  child: Text(
                                    t.name[0].toUpperCase() +
                                        t.name.substring(1),
                                  ),
                                ),
                              )
                              .toList(),
                        ),
                        const SizedBox(height: 12),

                        // Subject
                        _buildField(
                          subjectCtrl,
                          'Subject',
                          'e.g., Mathematics, Physics',
                        ),
                        const SizedBox(height: 20),

                        // Buttons
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: () => Navigator.pop(ctx),
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 14,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  side: const BorderSide(
                                    color: Color(0xFFE5E7EB),
                                  ),
                                ),
                                child: const Text(
                                  'Cancel',
                                  style: TextStyle(color: Color(0xFF374151)),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: ElevatedButton(
                                onPressed: () {
                                  if (titleCtrl.text.isEmpty ||
                                      subjectCtrl.text.isEmpty ||
                                      courseIdCtrl.text.isEmpty) {
                                    _showError('Please fill all fields');
                                    return;
                                  }
                                  Navigator.pop(ctx);
                                  _addContent(
                                    titleCtrl.text,
                                    selectedType,
                                    subjectCtrl.text,
                                    courseIdCtrl.text, // ← from input
                                  );
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.black,
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 14,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  elevation: 0,
                                ),
                                child: const Text(
                                  'Add Content',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
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

  Widget _buildField(
    TextEditingController ctrl,
    String label,
    String hint, {
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: Color(0xFF374151),
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: ctrl,
          keyboardType: keyboardType,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: Color(0xFF9CA3AF)),
            filled: true,
            fillColor: const Color(0xFFF9FAFB),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.black, width: 2),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 12,
            ),
          ),
        ),
      ],
    );
  }

  // ── build ───────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final filters = ['all', 'video', 'document', 'image', 'assignment'];

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Content Library',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF111827),
                        ),
                      ),
                      Text(
                        '${_content.length} items',
                        style: const TextStyle(
                          fontSize: 13,
                          color: Color(0xFF6B7280),
                        ),
                      ),
                    ],
                  ),
                  GestureDetector(
                    onTap: _showAddModal,
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: const BoxDecoration(
                        color: Colors.black,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.add,
                        color: Colors.white,
                        size: 22,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: TextField(
                onChanged: (v) => setState(() => _searchTerm = v),
                decoration: InputDecoration(
                  hintText: 'Search content...',
                  hintStyle: const TextStyle(color: Color(0xFF9CA3AF)),
                  prefixIcon: const Icon(
                    Icons.search,
                    color: Color(0xFF9CA3AF),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Colors.black, width: 2),
                  ),
                  contentPadding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              height: 38,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: filters.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (_, i) {
                  final f = filters[i];
                  final selected = _filterType == f;
                  return GestureDetector(
                    onTap: () => setState(() => _filterType = f),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: selected ? Colors.black : Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: selected
                              ? Colors.black
                              : const Color(0xFFE5E7EB),
                        ),
                      ),
                      child: Text(
                        f[0].toUpperCase() + f.substring(1),
                        style: TextStyle(
                          fontSize: 13,
                          color: selected
                              ? Colors.white
                              : const Color(0xFF6B7280),
                          fontWeight: selected
                              ? FontWeight.w600
                              : FontWeight.w400,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : _filtered.isEmpty
                  ? Center(
                      child: Text(
                        _activeCourseId == 0
                            ? 'Add content to get started'
                            : 'No content found',
                        style: const TextStyle(color: Color(0xFF6B7280)),
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                      itemCount: _filtered.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (_, index) {
                        final item = _filtered[index];
                        final color = _getColor(item.type);
                        return Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.04),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                            border: Border.all(color: const Color(0xFFF3F4F6)),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 46,
                                height: 46,
                                decoration: BoxDecoration(
                                  color: color.withOpacity(0.12),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(
                                  _getIcon(item.type),
                                  color: color,
                                  size: 22,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      item.title,
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: Color(0xFF111827),
                                      ),
                                    ),
                                    Text(
                                      item.subject,
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: Color(0xFF6B7280),
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        Text(
                                          item.size,
                                          style: const TextStyle(
                                            fontSize: 11,
                                            color: Color(0xFF9CA3AF),
                                          ),
                                        ),
                                        const SizedBox(width: 10),
                                        const Icon(
                                          Icons.visibility_outlined,
                                          size: 12,
                                          color: Color(0xFF9CA3AF),
                                        ),
                                        const SizedBox(width: 2),
                                        Text(
                                          '${item.views}',
                                          style: const TextStyle(
                                            fontSize: 11,
                                            color: Color(0xFF9CA3AF),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              IconButton(
                                onPressed: () => setState(
                                  () => _content.removeWhere(
                                    (c) => c.id == item.id,
                                  ),
                                ),
                                icon: const Icon(
                                  Icons.delete_outline,
                                  color: Colors.black,
                                  size: 20,
                                ),
                                style: IconButton.styleFrom(
                                  backgroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
