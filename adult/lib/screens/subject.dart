import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../Model/subject_model.dart';
import '../service/subject_service.dart';
import 'package:adult/Controller/auth_controller.dart';
import 'package:adult/service/sync_service.dart';

class SubjectPage extends StatefulWidget {
  const SubjectPage({super.key});

  @override
  State<SubjectPage> createState() => _SubjectPageState();
}

class _SubjectPageState extends State<SubjectPage> {
  final TextEditingController _searchController = TextEditingController();
  late subjectService _service;
  String _searchQuery = '';
  List<subjectModel> _subjects = [];
  bool _isLoading = true;
  String? _errorMessage;
  bool _loaded = false; // prevent duplicate calls

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_loaded) {
      _loaded = true;
      _service = subjectService(db: context.read<SyncService>().db);
      _loadSubjects();
    }
  }

  Future<void> _loadSubjects() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
      final controller = Provider.of<AuthController>(context, listen: false);
      final programmeId = controller.programmeId;

      print('>>> SubjectPage programmeId: $programmeId');

      if (programmeId == null) {
        setState(() {
          _errorMessage = 'No programme selected. Please log in again.';
          _isLoading = false;
        });
        return;
      }

      final data = await _service.getSubjectsByProgramme(programmeId);
      setState(() {
        _subjects = data;
        _isLoading = false;
      });
    } catch (e) {
      print('>>> SubjectPage error: $e');
      setState(() {
        _errorMessage = 'Failed to load subjects. Please try again.';
        _isLoading = false;
      });
    }
  }

  List<subjectModel> get _filtered => _searchQuery.isEmpty
      ? _subjects
      : _subjects
      .where(
        (s) =>
    s.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
        s.code.toLowerCase().contains(_searchQuery.toLowerCase()),
  )
      .toList();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header ──────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Matches the "Browse Courses" card's icon on the
                      // dashboard (same tag) — flies in and grows into
                      // this badge when the page is opened from there.
                      Hero(
                        tag: 'browse-courses-icon',
                        child: Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.menu_book_rounded,
                            color: Colors.black,
                            size: 22,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Subjects',
                              style: TextStyle(
                                fontSize: 26,
                                fontWeight: FontWeight.w800,
                                color: Colors.black,
                                letterSpacing: -0.5,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Explore and enrol in a course below',
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey.shade600,
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // ── Search bar ──────────────────────────────
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFFE4E4E4)),
                    ),
                    child: TextField(
                      controller: _searchController,
                      onChanged: (v) => setState(() => _searchQuery = v),
                      decoration: InputDecoration(
                        hintText: 'What do you want to learn?',
                        hintStyle: TextStyle(
                          color: Colors.grey.shade400,
                          fontSize: 13.5,
                        ),
                        prefixIcon: Icon(
                          Icons.search_rounded,
                          color: Colors.grey.shade400,
                        ),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                          vertical: 14,
                          horizontal: 4,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // ── Body ────────────────────────────────────────────
            Expanded(child: _buildBody()),
          ],
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: Colors.black),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.wifi_off_rounded, size: 48, color: Colors.grey.shade300),
            const SizedBox(height: 12),
            Text(
              _errorMessage!,
              style: TextStyle(color: Colors.grey.shade500, fontSize: 13),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _loadSubjects,
              icon: const Icon(Icons.refresh_rounded, size: 16),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      );
    }

    if (_filtered.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off_rounded,
              size: 48,
              color: Colors.grey.shade300,
            ),
            const SizedBox(height: 8),
            Text(
              'No courses found',
              style: TextStyle(color: Colors.grey.shade400),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      color: Colors.black,
      onRefresh: _loadSubjects,
      child: GridView.builder(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 14,
          crossAxisSpacing: 14,
          childAspectRatio: 0.82,
        ),
        itemCount: _filtered.length,
        itemBuilder: (context, index) => _SubjectCard(subject: _filtered[index]),
      ),
    );
  }
}

// ── Subject Card ──────────────────────────────────────────────────────────────

class _SubjectCard extends StatefulWidget {
  final subjectModel subject;
  const _SubjectCard({required this.subject});

  @override
  State<_SubjectCard> createState() => _SubjectCardState();
}

class _SubjectCardState extends State<_SubjectCard> {
  bool _pressed = false;

  void _enter() {
    Navigator.pushNamed(
      context,
      '/coursepage',
      arguments: widget.subject.id, // ← pass subject id
    );
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Entering ${widget.subject.name}...'),
        duration: const Duration(seconds: 1),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.subject;
    return AnimatedScale(
      scale: _pressed ? 0.96 : 1.0,
      duration: const Duration(milliseconds: 120),
      child: GestureDetector(
        onTapDown: (_) => setState(() => _pressed = true),
        onTapUp: (_) => setState(() => _pressed = false),
        onTapCancel: () => setState(() => _pressed = false),
        onTap: _enter,
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFE4E4E4)),
          ),
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: Colors.black,
                      borderRadius: BorderRadius.circular(13),
                    ),
                    child: const Icon(
                      Icons.menu_book_rounded,
                      color: Colors.white,
                      size: 22,
                    ),
                  ),
                  GestureDetector(
                    onTap: _enter,
                    child: Container(
                      width: 30,
                      height: 30,
                      decoration: const BoxDecoration(
                        color: Colors.black,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.arrow_forward_rounded,
                        color: Colors.white,
                        size: 15,
                      ),
                    ),
                  ),
                ],
              ),
              const Spacer(),
              Text(
                s.name,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: Colors.black,
                  height: 1.25,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                s.code,
                style: TextStyle(
                  fontSize: 11.5,
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}