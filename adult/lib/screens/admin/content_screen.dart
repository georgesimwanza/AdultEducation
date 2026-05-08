import 'package:flutter/material.dart';

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
}

class ContentScreen extends StatefulWidget {
  const ContentScreen({super.key});

  @override
  State<ContentScreen> createState() => _ContentScreenState();
}

class _ContentScreenState extends State<ContentScreen> {
  String _searchTerm = '';
  String _filterType = 'all';

  List<ContentItem> _content = [
    ContentItem(
      id: '1',
      title: 'Introduction to Algebra',
      type: ContentType.video,
      subject: 'Mathematics',
      uploadDate: DateTime(2026, 4, 15),
      size: '125 MB',
      views: 245,
    ),
    ContentItem(
      id: '2',
      title: 'Physics Chapter 5 Notes',
      type: ContentType.document,
      subject: 'Physics',
      uploadDate: DateTime(2026, 4, 20),
      size: '2.5 MB',
      views: 189,
    ),
    ContentItem(
      id: '3',
      title: 'Cell Structure Diagram',
      type: ContentType.image,
      subject: 'Biology',
      uploadDate: DateTime(2026, 4, 22),
      size: '1.2 MB',
      views: 156,
    ),
    ContentItem(
      id: '4',
      title: 'Essay Assignment',
      type: ContentType.assignment,
      subject: 'English',
      uploadDate: DateTime(2026, 4, 25),
      size: '850 KB',
      views: 312,
    ),
  ];

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
        return const Color.fromARGB(255, 222, 120, 46);
    }
  }

  void _showAddModal() {
    final titleCtrl = TextEditingController();
    final subjectCtrl = TextEditingController();
    ContentType selectedType = ContentType.document;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Container(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom,
          ),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
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
                      icon: const Icon(Icons.close, color: Color(0xFF9CA3AF)),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _buildField(
                  titleCtrl,
                  'Content Title',
                  'Enter content title',
                  const Color.fromARGB(255, 0, 0, 0),
                ),
                const SizedBox(height: 12),
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
                  onChanged: (v) => setModalState(() => selectedType = v!),
                  decoration: InputDecoration(
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
                      borderSide: const BorderSide(
                        color: Color.fromARGB(255, 0, 0, 0),
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
                            t.name[0].toUpperCase() + t.name.substring(1),
                          ),
                        ),
                      )
                      .toList(),
                ),
                const SizedBox(height: 12),
                _buildField(
                  subjectCtrl,
                  'Subject',
                  'e.g., Mathematics, Physics',
                  const Color.fromARGB(255, 0, 0, 0),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(ctx),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          side: const BorderSide(color: Color(0xFFE5E7EB)),
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
                          if (titleCtrl.text.isNotEmpty &&
                              subjectCtrl.text.isNotEmpty) {
                            setState(() {
                              _content.add(
                                ContentItem(
                                  id: DateTime.now().millisecondsSinceEpoch
                                      .toString(),
                                  title: titleCtrl.text,
                                  type: selectedType,
                                  subject: subjectCtrl.text,
                                  uploadDate: DateTime.now(),
                                  size: '1.0 MB',
                                  views: 0,
                                ),
                              );
                            });
                            Navigator.pop(ctx);
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color.fromARGB(255, 0, 0, 0),
                          padding: const EdgeInsets.symmetric(vertical: 14),
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
                const SizedBox(height: 8),
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
    String hint,
    Color accent,
  ) {
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
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: Color.fromARGB(255, 0, 0, 0)),
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
              borderSide: BorderSide(color: accent, width: 2),
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
                        color: Color.fromARGB(255, 0, 0, 0),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Color(0x3322C55E),
                            blurRadius: 12,
                            offset: Offset(0, 4),
                          ),
                        ],
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
                  hintStyle: const TextStyle(
                    color: Color.fromARGB(255, 0, 0, 0),
                  ),
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
                    borderSide: const BorderSide(
                      color: Color.fromARGB(255, 0, 0, 0),
                      width: 2,
                    ),
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
                        color: selected
                            ? const Color.fromARGB(255, 0, 0, 0)
                            : Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: selected
                              ? const Color.fromARGB(255, 0, 0, 0)
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
              child: ListView.separated(
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
                                  const SizedBox(width: 10),
                                  Text(
                                    '${item.uploadDate.month}/${item.uploadDate.day}/${item.uploadDate.year}',
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
                            () => _content.removeWhere((c) => c.id == item.id),
                          ),
                          icon: const Icon(
                            Icons.delete_outline,
                            color: Color.fromARGB(255, 0, 0, 0),
                            size: 20,
                          ),
                          style: IconButton.styleFrom(
                            backgroundColor: const Color.fromARGB(
                              255,
                              255,
                              255,
                              255,
                            ),
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
