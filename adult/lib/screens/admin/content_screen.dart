import 'package:adult/service/auth_service.dart';
import 'package:file_picker/file_picker.dart';
import 'package:adult/Model/content.dart';
import 'package:adult/Model/subject_model.dart';
import 'package:adult/service/subject_service.dart';
import 'package:adult/service/sync_service.dart';
import 'package:provider/provider.dart';
import 'package:adult/service/contentService.dart';
import 'package:adult/service/cdn_supabase.dart';
import 'package:adult/Controller/auth_controller.dart'; // ← added, adjust if getInstitution lives elsewhere
import 'package:adult/core/admin_table.dart';
import 'package:adult/core/responsive.dart';
import 'package:flutter/material.dart';
import 'package:adult/screens/color.dart';

class ContentScreen extends StatefulWidget {
  const ContentScreen({super.key});

  @override
  State<ContentScreen> createState() => _ContentScreenState();
}

class _ContentScreenState extends State<ContentScreen> {
  String _searchTerm = '';
  String _filterType = 'all';

  List<ContentModel> _content = [];
  bool _loading = false;
  bool _uploading = false;

  @override
  void initState() {
    super.initState();
    _fetchAllContent();
  }

  Future<void> _fetchAllContent() async {
    setState(() => _loading = true);
    try {
      final data = await contentService(db: context.read<SyncService>().db).getAllContent();
      setState(() {
        _content = data;
      });
    } catch (e) {
      _showError("Could not update library: ${e.toString()}");
    } finally {
      setState(() => _loading = false);
    }
  }

  // ── POST via contentService ─────────────────────────────────────────────
  Future<void> _addContent(
    String title,
    String type,
    String courseIdText,
    PlatformFile? file,
  ) async {
    final courseId = int.tryParse(courseIdText);
    if (courseId == null) {
      _showError('Course ID must be a valid number');
      return;
    }

    // ← pull the real saved institution ID instead of hardcoding
    final institutionId = await AuthService().getInstitution();
    if (institutionId == null) {
      _showError('No institution found — please log in again');
      return;
    }

    String fileUrl = '';
    if (file != null) {
      setState(() => _uploading = true);
      final url = await CdnSupabaseService().uploadContent(file, courseIdText);
      setState(() => _uploading = false);
      if (url == null) {
        _showError('File upload failed');
        return;
      }
      fileUrl = url;
    }

    try {
      await contentService().addContent(
        title: title,
        type: type,
        fileUrl: fileUrl,
        courseId: courseId,
        institutionId: institutionId,
      );
      await _fetchAllContent();
    } catch (e) {
      _showError(e.toString());
    }
  }

  void _showError(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  List<ContentModel> get _filtered => _content.where((item) {
    final matchSearch =
        item.title.toLowerCase().contains(_searchTerm.toLowerCase()) ||
        _typeKey(item.type).contains(_searchTerm.toLowerCase());
    final matchFilter =
        _filterType == 'all' || _typeKey(item.type) == _filterType;
    return matchSearch && matchFilter;
  }).toList();

  /// Older items were saved as "assignment"; they are quizzes, so they are
  /// shown and filtered as quizzes.
  static String _typeKey(String type) {
    final t = type.toLowerCase();
    return t == 'assignment' ? 'quiz' : t;
  }

  static String _typeLabel(String type) {
    final t = _typeKey(type);
    return t.isEmpty ? '-' : t[0].toUpperCase() + t.substring(1);
  }

  IconData _getIcon(String type) {
    switch (_typeKey(type)) {
      case 'video':
        return Icons.play_circle_outline;
      case 'image':
        return Icons.image_outlined;
      case 'quiz':
        return Icons.quiz_outlined;
      default:
        return Icons.description_outlined;
    }
  }

  Color _getColor(String type) {
    switch (_typeKey(type)) {
      case 'video':
        return const Color(0xFFEF4444);
      case 'image':
        return const Color(0xFF22C55E);
      case 'quiz':
        return const Color(0xFFDE782E);
      default:
        return const Color(0xFF3B82F6);
    }
  }

  // ── Add modal ────────────────────────────────────────────────────────────
  Future<void> _showAddModal() async {
    final titleCtrl = TextEditingController();
    String selectedType = 'document';
    PlatformFile? selectedFile;

    // Pick the programme and subject by name (from the local copy synced at
    // login) instead of typing a course ID.
    final db = context.read<SyncService>().db;
    final programmes = db == null
        ? <Map<String, Object?>>[]
        : await db.query('programmes', orderBy: 'name');
    if (!mounted) return;
    int? programmeId;
    int? subjectId;
    var subjects = <subjectModel>[];

    final contentTypes = ['document', 'video', 'image', 'quiz'];

    showAdaptiveSheet(
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
            decoration: BoxDecoration(
              color: EduColors.surface,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Column(
              children: [
                Container(
                  margin: const EdgeInsets.only(top: 12, bottom: 8),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: EduColors.border,
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
                            Text(
                              'Add New Content',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: EduColors.textPrimary,
                              ),
                            ),
                            IconButton(
                              onPressed: () => Navigator.pop(ctx),
                              icon: Icon(
                                Icons.close,
                                color: EduColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        ResponsiveFormRow(
                          children: [
                            _buildPicker(
                              label: 'Programme',
                              value: programmeId,
                              hint: programmes.isEmpty
                                  ? 'No programmes available'
                                  : 'Choose a programme',
                              items: [
                                for (final p in programmes)
                                  DropdownMenuItem(
                                    value: p['id'] as int,
                                    child: Text(
                                      p['name'] as String? ?? '',
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                              ],
                              onChanged: (v) async {
                                final list = v == null || db == null
                                    ? <subjectModel>[]
                                    : await subjectService(db: db)
                                        .getSubjectsByProgramme(v);
                                setModalState(() {
                                  programmeId = v;
                                  subjectId = null;
                                  subjects = list;
                                });
                              },
                            ),
                            _buildPicker(
                              // Rebuilt when the programme changes so the
                              // previous subject is cleared.
                              key: ValueKey(programmeId),
                              label: 'Subject',
                              value: subjectId,
                              hint: programmeId == null
                                  ? 'Choose a programme first'
                                  : subjects.isEmpty
                                      ? 'No subjects in this programme'
                                      : 'Choose a subject',
                              items: [
                                for (final sub in subjects)
                                  DropdownMenuItem(
                                    value: sub.id,
                                    child: Text(
                                      sub.code.isEmpty
                                          ? sub.name
                                          : '${sub.name} (${sub.code})',
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                              ],
                              onChanged: (v) =>
                                  setModalState(() => subjectId = v),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        _buildField(
                          titleCtrl,
                          'Content Title',
                          'Enter content title',
                        ),
                        const SizedBox(height: 12),

                        ResponsiveFormRow(
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  'Content Type',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                    color: EduColors.textPrimary,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                DropdownButtonFormField<String>(
                                  value: selectedType,
                                  onChanged: (v) =>
                                      setModalState(() => selectedType = v!),
                                  decoration: InputDecoration(
                                    filled: true,
                                    fillColor: EduColors.background,
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide(
                                        color: EduColors.border,
                                      ),
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide(
                                        color: EduColors.border,
                                      ),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: const BorderSide(
                                        color: EduColors.primary,
                                        width: 2,
                                      ),
                                    ),
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 14,
                                      vertical: 4,
                                    ),
                                  ),
                                  items: contentTypes
                                      .map(
                                        (t) => DropdownMenuItem(
                                          value: t,
                                          child: Text(
                                            t[0].toUpperCase() + t.substring(1),
                                          ),
                                        ),
                                      )
                                      .toList(),
                                ),
                              ],
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  'Content File',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                    color: EduColors.textPrimary,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                OutlinedButton.icon(
                                  onPressed: () async {
                                    // Browsers have no file paths; load the bytes.
                                    final result = await FilePicker.platform
                                        .pickFiles(withData: true);
                                    if (result != null &&
                                        result.files.single.bytes != null) {
                                      setModalState(() {
                                        selectedFile = result.files.single;
                                      });
                                    }
                                  },
                                  style: OutlinedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(vertical: 14),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    side: BorderSide(color: EduColors.border),
                                  ),
                                  icon: const Icon(
                                    Icons.attach_file,
                                    color: EduColors.primary,
                                  ),
                                  label: Text(
                                    selectedFile == null
                                        ? 'Attach File'
                                        : selectedFile!.name,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(color: EduColors.textPrimary),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),

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
                                  side: BorderSide(
                                    color: EduColors.border,
                                  ),
                                ),
                                child: Text(
                                  'Cancel',
                                  style: TextStyle(color: EduColors.textPrimary),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: ElevatedButton(
                                onPressed: _uploading
                                    ? null
                                    : () {
                                        if (titleCtrl.text.isEmpty ||
                                            subjectId == null) {
                                          _showError(
                                              'Choose a subject and enter a title');
                                          return;
                                        }
                                        Navigator.pop(ctx);
                                        _addContent(
                                          titleCtrl.text,
                                          selectedType,
                                          '$subjectId',
                                          selectedFile,
                                        );
                                      },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: EduColors.primary,
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

  /// Labelled dropdown matching the form's text fields.
  Widget _buildPicker({
    Key? key,
    required String label,
    required int? value,
    required String hint,
    required List<DropdownMenuItem<int>> items,
    required ValueChanged<int?> onChanged,
  }) {
    return Column(
      key: key,
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: EduColors.textPrimary,
          ),
        ),
        const SizedBox(height: 6),
        DropdownButtonFormField<int>(
          initialValue: value,
          isExpanded: true,
          hint: Text(hint, overflow: TextOverflow.ellipsis),
          items: items,
          onChanged: onChanged,
          decoration: InputDecoration(
            filled: true,
            fillColor: EduColors.background,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: EduColors.border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: EduColors.border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: EduColors.primary, width: 2),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 4,
            ),
          ),
        ),
      ],
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
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: EduColors.textPrimary,
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: ctrl,
          keyboardType: keyboardType,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: EduColors.textSecondary),
            filled: true,
            fillColor: EduColors.background,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: EduColors.border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: EduColors.border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: EduColors.primary, width: 2),
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

  Widget _contentCard(ContentModel item) {
    final color = _getColor(item.type);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: EduColors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(color: EduColors.border),
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
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: EduColors.textPrimary,
                  ),
                ),
                Text(
                  'Type: ${_typeLabel(item.type)}',
                  style: TextStyle(
                    fontSize: 12,
                    color: EduColors.textSecondary,
                  ),
                ),
                if (item.fileUrl.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    item.fileUrl,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 11,
                      color: EduColors.textSecondary,
                    ),
                  ),
                ],
              ],
            ),
          ),
          _deleteButton(item),
        ],
      ),
    );
  }

  Widget _deleteButton(ContentModel item) {
    return IconButton(
      onPressed: () => setState(
        () => _content.removeWhere(
          (c) => c.id == item.id,
        ),
      ),
      icon: const Icon(
        Icons.delete_outline,
        color: EduColors.primary,
        size: 20,
      ),
      style: IconButton.styleFrom(
        backgroundColor: EduColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filters = ['all', 'video', 'document', 'image', 'quiz'];

    return Scaffold(
      backgroundColor: EduColors.background,
      body: SafeArea(
        child: Column(
          children: [
            ResponsiveCenter(child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Global Content Library',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          color: EduColors.textPrimary,
                        ),
                      ),
                      Text(
                        '${_filtered.length} visible items',
                        style: TextStyle(
                          fontSize: 13,
                          color: EduColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                  HoverCard(child: GestureDetector(
                    onTap: _showAddModal,
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: const BoxDecoration(
                        color: EduColors.primary,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.add,
                        color: Colors.white,
                        size: 22,
                      ),
                    ),
                  )),
                ],
              ),
            )),
            ResponsiveCenter(child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: TextField(
                onChanged: (v) => setState(() => _searchTerm = v),
                decoration: InputDecoration(
                  hintText: 'Search by title or type...',
                  hintStyle: TextStyle(color: EduColors.textSecondary),
                  prefixIcon: Icon(
                    Icons.search,
                    color: EduColors.textSecondary,
                  ),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: EduColors.border),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: EduColors.border),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: EduColors.primary, width: 2),
                  ),
                  contentPadding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            )),
            const SizedBox(height: 10),
            ResponsiveCenter(child: SizedBox(
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
                        color: selected ? EduColors.primary : Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: selected
                              ? EduColors.primary
                              : EduColors.border,
                        ),
                      ),
                      child: Text(
                        f[0].toUpperCase() + f.substring(1),
                        style: TextStyle(
                          fontSize: 13,
                          color: selected
                              ? Colors.white
                              : EduColors.textSecondary,
                          fontWeight: selected
                              ? FontWeight.w600
                              : FontWeight.w400,
                        ),
                      ),
                    ),
                  );
                },
              ),
            )),
            const SizedBox(height: 10),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : _filtered.isEmpty
                  ? Center(
                      child: Text(
                        'No institutional content found matching selection criteria',
                        style: TextStyle(color: EduColors.textSecondary),
                      ),
                    )
                  : context.isDesktop
                  ? CenteredScrollPadding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                      builder: (context, padding) => AdminDataTable(
                        padding: padding,
                        columns: const [
                          DataColumn(label: Text('Title')),
                          DataColumn(label: Text('Type')),
                          DataColumn(label: Text('File')),
                          DataColumn(label: Text('')),
                        ],
                        rows: [
                          for (final item in _filtered)
                            DataRow(cells: [
                              DataCell(Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(_getIcon(item.type),
                                      color: _getColor(item.type), size: 20),
                                  const SizedBox(width: 10),
                                  TableText(item.title,
                                      style: const TextStyle(
                                          fontWeight: FontWeight.w600)),
                                ],
                              )),
                              DataCell(Text(_typeLabel(item.type))),
                              DataCell(TableText(
                                item.fileUrl.isEmpty ? '-' : item.fileUrl,
                                maxWidth: 360,
                                style: TextStyle(
                                    color: EduColors.textSecondary, fontSize: 12.5),
                              )),
                              DataCell(_deleteButton(item)),
                            ]),
                        ],
                      ),
                    )
                  : context.isTablet
                  ? CenteredScrollPadding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                      builder: (context, padding) => SingleChildScrollView(
                        padding: padding,
                        child: ResponsiveGrid(
                          spacing: 10,
                          runSpacing: 10,
                          children: [
                            for (final item in _filtered) _contentCard(item),
                          ],
                        ),
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                      itemCount: _filtered.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (_, index) {
                        return _contentCard(_filtered[index]);
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
