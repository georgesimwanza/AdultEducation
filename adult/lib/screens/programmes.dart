import 'package:flutter/material.dart';
import 'package:adult/screens/color.dart';
import '../Service/programme_service.dart';
import '../Model/programme_model.dart';

typedef Programme = ProgrammeModel;

// Kept in case other screens import these from this file; they now map to
// the shared palette so nothing stays purple by accident.
const kPurple = EduColors.primary;
const kPurpleBg = EduColors.primarySoft;
const kWhite = Colors.white;
const kGrey = EduColors.background;

class ProgrammePage extends StatefulWidget {
  const ProgrammePage({super.key});

  @override
  State<ProgrammePage> createState() => _ProgrammePageState();
}

class _ProgrammePageState extends State<ProgrammePage> {
  late Future<List<ProgrammeModel>> _programmesFuture;
  final TextEditingController _searchController = TextEditingController();
  String _query = '';

  @override
  void initState() {
    super.initState();
    _programmesFuture = ProgrammeService().getProgrammes();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _reload() async {
    setState(() {
      _programmesFuture = ProgrammeService().getProgrammes();
    });
    try {
      await _programmesFuture;
    } catch (_) {
      // The FutureBuilder shows the error state.
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: EduColors.background,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            Expanded(
              child: FutureBuilder<List<ProgrammeModel>>(
                future: _programmesFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child:
                      CircularProgressIndicator(color: EduColors.primary),
                    );
                  }

                  if (snapshot.hasError) {
                    return _messageState(
                      icon: Icons.cloud_off_rounded,
                      title: "Couldn't load programmes",
                      message:
                      'Check your connection and try again.\n${snapshot.error}',
                      showRetry: true,
                    );
                  }

                  final all = snapshot.data ?? [];
                  if (all.isEmpty) {
                    return _messageState(
                      icon: Icons.school_outlined,
                      title: 'No programmes yet',
                      message: 'Available programmes will appear here.',
                    );
                  }

                  final programmes = _query.isEmpty
                      ? all
                      : all
                      .where((p) => p.name
                      .toLowerCase()
                      .contains(_query.toLowerCase()))
                      .toList();

                  if (programmes.isEmpty) {
                    return _messageState(
                      icon: Icons.search_off_rounded,
                      title: 'No programmes found',
                      message: 'Try a different name.',
                    );
                  }

                  return RefreshIndicator(
                    color: EduColors.primary,
                    onRefresh: _reload,
                    child: GridView.builder(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
                      itemCount: programmes.length,
                      gridDelegate:
                      const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        mainAxisSpacing: 14,
                        crossAxisSpacing: 14,
                        childAspectRatio: 0.95,
                      ),
                      itemBuilder: (_, i) => _EntranceFade(
                        index: i,
                        child: _ProgrammeCard(
                          programme: programmes[i],
                          colorIndex: i,
                        ),
                      ),
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

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
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
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Choose programme',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: EduColors.textPrimary,
                        letterSpacing: -0.3,
                      ),
                    ),
                    Text(
                      'Pick the one you want to enrol in',
                      style: TextStyle(
                        fontSize: 12,
                        color: EduColors.textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Container(
            height: 54,
            decoration: BoxDecoration(
              color: EduColors.surface,
              borderRadius: BorderRadius.circular(27),
              border: Border.all(color: EduColors.border),
            ),
            child: TextField(
              controller: _searchController,
              onChanged: (v) => setState(() => _query = v),
              cursorColor: EduColors.primary,
              style:
              const TextStyle(color: EduColors.textPrimary, fontSize: 14),
              decoration: InputDecoration(
                hintText: 'Search programmes',
                hintStyle: const TextStyle(
                    color: EduColors.textSecondary, fontSize: 14),
                prefixIcon: const Icon(Icons.search_rounded,
                    color: EduColors.textSecondary),
                suffixIcon: _query.isEmpty
                    ? null
                    : IconButton(
                  icon: const Icon(Icons.close_rounded,
                      color: EduColors.textSecondary, size: 20),
                  onPressed: () {
                    _searchController.clear();
                    setState(() => _query = '');
                  },
                ),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _messageState({
    required IconData icon,
    required String title,
    required String message,
    bool showRetry = false,
  }) {
    return RefreshIndicator(
      color: EduColors.primary,
      onRefresh: _reload,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 32),
        children: [
          const SizedBox(height: 60),
          Center(
            child: Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: EduColors.primarySoft,
                borderRadius: BorderRadius.circular(22),
              ),
              child: Icon(icon, color: EduColors.primary, size: 34),
            ),
          ),
          const SizedBox(height: 18),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w800,
              color: EduColors.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 13,
              height: 1.4,
              color: EduColors.textSecondary,
            ),
          ),
          if (showRetry) ...[
            const SizedBox(height: 18),
            Center(
              child: ElevatedButton.icon(
                onPressed: _reload,
                icon: const Icon(Icons.refresh_rounded, size: 18),
                label: const Text('Try again'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: EduColors.primary,
                  foregroundColor: EduColors.onPrimary,
                  elevation: 0,
                  padding:
                  const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ── Programme card ─────────────────────────────────────────────────────────

class _ProgrammeCard extends StatefulWidget {
  final ProgrammeModel programme;
  final int colorIndex;
  const _ProgrammeCard({required this.programme, required this.colorIndex});

  @override
  State<_ProgrammeCard> createState() => _ProgrammeCardState();
}

class _ProgrammeCardState extends State<_ProgrammeCard> {
  bool _pressed = false;

  static const List<Color> _fg = [
    EduColors.primary,
    EduColors.accent,
    EduColors.success,
  ];
  static const List<Color> _bg = [
    EduColors.primarySoft,
    EduColors.accentSoft,
    EduColors.successSoft,
  ];

  void _showDetail(BuildContext context) async {
    final navigator = Navigator.of(context); // capture before await

    final result = await showModalBottomSheet<ProgrammeModel>(
      context: context,
      backgroundColor: EduColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (_) => _ProgrammeDetailSheet(
        programme: widget.programme,
        fg: _fg[widget.colorIndex % _fg.length],
        bg: _bg[widget.colorIndex % _bg.length],
      ),
    );

    if (result != null) {
      navigator.pop(result); // use captured navigator
    }
  }

  @override
  Widget build(BuildContext context) {
    final fg = _fg[widget.colorIndex % _fg.length];
    final bg = _bg[widget.colorIndex % _bg.length];

    return AnimatedScale(
      scale: _pressed ? 0.96 : 1.0,
      duration: const Duration(milliseconds: 120),
      child: GestureDetector(
        onTapDown: (_) => setState(() => _pressed = true),
        onTapUp: (_) => setState(() => _pressed = false),
        onTapCancel: () => setState(() => _pressed = false),
        onTap: () => _showDetail(context),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: EduColors.surface,
            borderRadius: BorderRadius.circular(22),
            boxShadow: EduColors.cardShadow,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: bg,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(Icons.school_rounded, color: fg, size: 24),
              ),
              const Spacer(),
              Text(
                widget.programme.name,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 14,
                  height: 1.25,
                  color: EduColors.textPrimary,
                ),
              ),
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerRight,
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: const BoxDecoration(
                    color: EduColors.primary,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.arrow_forward_rounded,
                      color: EduColors.onPrimary, size: 16),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Detail sheet ───────────────────────────────────────────────────────────

class _ProgrammeDetailSheet extends StatelessWidget {
  final ProgrammeModel programme;
  final Color fg;
  final Color bg;
  const _ProgrammeDetailSheet({
    required this.programme,
    required this.fg,
    required this.bg,
  });

  @override
  Widget build(BuildContext context) {
    final hasDescription =
        programme.description != null && programme.description!.isNotEmpty;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: EduColors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 22),
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: bg,
                borderRadius: BorderRadius.circular(18),
              ),
              child: Icon(Icons.school_rounded, color: fg, size: 28),
            ),
            const SizedBox(height: 16),
            Text(
              programme.name,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                height: 1.25,
                color: EduColors.textPrimary,
              ),
            ),
            if (hasDescription) ...[
              const SizedBox(height: 10),
              Text(
                programme.description!,
                style: const TextStyle(
                  fontSize: 14,
                  height: 1.5,
                  color: EduColors.textSecondary,
                ),
              ),
            ],
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context, programme),
                style: ElevatedButton.styleFrom(
                  backgroundColor: EduColors.primary,
                  foregroundColor: EduColors.onPrimary,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(28),
                  ),
                ),
                child: const Text(
                  'Enrol Now',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Fades + slides each card in with a small stagger.
class _EntranceFade extends StatelessWidget {
  final int index;
  final Widget child;

  const _EntranceFade({required this.index, required this.child});

  @override
  Widget build(BuildContext context) {
    final delay = (index * 50).clamp(0, 350);
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 350 + delay),
      curve: Curves.easeOutCubic,
      builder: (context, v, child) => Opacity(
        opacity: v,
        child: Transform.translate(
          offset: Offset(0, (1 - v) * 16),
          child: child,
        ),
      ),
      child: child,
    );
  }
}