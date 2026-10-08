import 'package:adult/service/announcement_service.dart';
import 'package:adult/service/sync_service.dart';
import 'package:adult/screens/color.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:adult/Model/Announcement_model.dart';

class NoticeBoardScreen extends StatefulWidget {
  const NoticeBoardScreen({super.key});

  @override
  State<NoticeBoardScreen> createState() => _NoticeBoardScreenState();
}

class _NoticeBoardScreenState extends State<NoticeBoardScreen> {
  // Built in initState once we can reach the SyncService's db via Provider —
  // a field initializer can't use context, and without db the service has
  // no offline fallback.
  late final AnnouncementService _service;

  late Future<List<AnnouncementModel>> _futureAnnouncements;

  // Local-only acknowledgment tracking — there's no "acknowledged" field
  // on AnnouncementModel/backend yet, so this resets on app restart.
  // To persist it, add an `isAcknowledged` column to the Announcement
  // entity, or store acknowledged IDs in SharedPreferences.
  final Set<int> _acknowledgedIds = {};

  @override
  void initState() {
    super.initState();
    final syncService = Provider.of<SyncService>(context, listen: false);
    _service = AnnouncementService(db: syncService.db);
    _futureAnnouncements = _loadAnnouncements();
  }

  Future<List<AnnouncementModel>> _loadAnnouncements() {
    return _service.getByInstitutionAndProgrammeFromPrefs();
  }

  Future<void> _refresh() async {
    setState(() {
      _futureAnnouncements = _loadAnnouncements();
    });
    try {
      await _futureAnnouncements;
    } catch (_) {
      // The FutureBuilder shows the error state; don't crash the refresh.
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: EduColors.background,
      body: SafeArea(
        child: Column(
          children: [
            _buildTopBar(),
            const SizedBox(height: 12),
            Expanded(
              child: RefreshIndicator(
                color: EduColors.primary,
                onRefresh: _refresh,
                child: FutureBuilder<List<AnnouncementModel>>(
                  future: _futureAnnouncements,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(
                        child: CircularProgressIndicator(
                            color: EduColors.primary),
                      );
                    }

                    if (snapshot.hasError) {
                      return _buildMessageState(
                        icon: Icons.cloud_off_rounded,
                        title: 'Could not load notices',
                        message:
                        'Check your connection and pull down to try again.',
                        detail: '${snapshot.error}',
                        showRetry: true,
                      );
                    }

                    final notices = snapshot.data ?? [];

                    if (notices.isEmpty) {
                      return _buildMessageState(
                        icon: Icons.campaign_outlined,
                        title: 'No notices yet',
                        message: 'New announcements will show up here.',
                      );
                    }

                    return ListView.builder(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
                      itemCount: notices.length,
                      itemBuilder: (context, index) {
                        return _EntranceFade(
                          index: index,
                          child: _buildNoticeCard(notices[index]),
                        );
                      },
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ───────────────────────── Top bar ─────────────────────────

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
          Expanded(
            child: FutureBuilder<List<AnnouncementModel>>(
              future: _futureAnnouncements,
              builder: (context, snapshot) {
                final unread = snapshot.hasData
                    ? snapshot.data!
                    .where((a) => !_acknowledgedIds.contains(a.id))
                    .length
                    : 0;
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Notice Board',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: EduColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      unread == 0 ? 'All caught up' : '$unread unread',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: unread == 0
                            ? EduColors.success
                            : EduColors.textSecondary,
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
          GestureDetector(
            onTap: _refresh,
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: EduColors.primarySoft,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.refresh_rounded,
                  color: EduColors.primary, size: 20),
            ),
          ),
        ],
      ),
    );
  }

  // ───────────────────────── States ─────────────────────────

  Widget _buildMessageState({
    required IconData icon,
    required String title,
    required String message,
    String? detail,
    bool showRetry = false,
  }) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 32),
      children: [
        const SizedBox(height: 110),
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
              onPressed: _refresh,
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
        if (detail != null) ...[
          const SizedBox(height: 18),
          Text(
            detail,
            textAlign: TextAlign.center,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 10,
              color: EduColors.textSecondary,
            ),
          ),
        ],
      ],
    );
  }

  // ───────────────────────── Notice card ─────────────────────────

  Widget _buildNoticeCard(AnnouncementModel notice) {
    final isAcknowledged = _acknowledgedIds.contains(notice.id);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: EduColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isAcknowledged ? EduColors.border : EduColors.primarySoft,
          width: isAcknowledged ? 1 : 1.5,
        ),
        boxShadow: isAcknowledged ? null : EduColors.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: isAcknowledged
                      ? EduColors.background
                      : EduColors.primarySoft,
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Icon(
                  Icons.campaign_rounded,
                  size: 22,
                  color: isAcknowledged
                      ? EduColors.textSecondary
                      : EduColors.primary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  notice.title,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    height: 1.35,
                    color: isAcknowledged
                        ? EduColors.textSecondary
                        : EduColors.textPrimary,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              if (isAcknowledged)
                Container(
                  padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: EduColors.successSoft,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text(
                    'READ',
                    style: TextStyle(
                      color: EduColors.success,
                      fontSize: 9,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.6,
                    ),
                  ),
                )
              else
                Container(
                  margin: const EdgeInsets.only(top: 4),
                  width: 9,
                  height: 9,
                  decoration: const BoxDecoration(
                    color: EduColors.accent,
                    shape: BoxShape.circle,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            notice.content,
            style: const TextStyle(
              fontSize: 13,
              color: EduColors.textSecondary,
              height: 1.55,
            ),
          ),
          const SizedBox(height: 14),
          const Divider(color: EduColors.border, thickness: 1, height: 1),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: const [
                  CircleAvatar(
                    radius: 12,
                    backgroundColor: EduColors.primarySoft,
                    child: Icon(Icons.person_rounded,
                        size: 14, color: EduColors.primary),
                  ),
                  SizedBox(width: 8),
                  Text(
                    'Admin',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: EduColors.textSecondary,
                    ),
                  ),
                ],
              ),
              _buildAcknowledgeButton(notice),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAcknowledgeButton(AnnouncementModel notice) {
    final isAcknowledged = _acknowledgedIds.contains(notice.id);

    return GestureDetector(
      onTap: () {
        final wasAcknowledged = isAcknowledged;
        setState(() {
          if (wasAcknowledged) {
            _acknowledgedIds.remove(notice.id);
          } else {
            _acknowledgedIds.add(notice.id);
          }
        });
        if (!wasAcknowledged) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              behavior: SnackBarBehavior.floating,
              backgroundColor: EduColors.textPrimary,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
              content: const Row(
                children: [
                  Icon(Icons.check_circle_rounded,
                      color: EduColors.success, size: 18),
                  SizedBox(width: 10),
                  Text(
                    'Announcement acknowledged',
                    style: TextStyle(color: EduColors.onPrimary),
                  ),
                ],
              ),
            ),
          );
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
          color: isAcknowledged ? EduColors.successSoft : EduColors.primary,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isAcknowledged
                  ? Icons.check_circle_rounded
                  : Icons.circle_outlined,
              size: 14,
              color: isAcknowledged ? EduColors.success : EduColors.onPrimary,
            ),
            const SizedBox(width: 6),
            Text(
              isAcknowledged ? 'Acknowledged' : 'Acknowledge',
              style: TextStyle(
                color:
                isAcknowledged ? EduColors.success : EduColors.onPrimary,
                fontWeight: FontWeight.w700,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Fades + slides each card in with a small delay after the one before it.
class _EntranceFade extends StatelessWidget {
  final int index;
  final Widget child;

  const _EntranceFade({required this.index, required this.child});

  @override
  Widget build(BuildContext context) {
    final delay = (index * 60).clamp(0, 400);
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