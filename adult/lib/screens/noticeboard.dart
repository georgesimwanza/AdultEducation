import 'package:adult/service/announcement_service.dart';
import 'package:adult/service/sync_service.dart';
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
  // no offline fallback, which is what caused the raw SocketException to
  // reach this screen instead of falling back to the local cache.
  late final AnnouncementService _service;

  late Future<List<AnnouncementModel>> _futureAnnouncements;

  // Local-only acknowledgment tracking — there's no "acknowledged" field
  // on AnnouncementModel/backend yet, so this resets on app restart.
  // If you want it to persist, either add an `isAcknowledged` column to
  // the Announcement entity, or store acknowledged IDs in SharedPreferences.
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
    await _futureAnnouncements;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        titleSpacing: 0,
        leading: const BackButton(),
        title: FutureBuilder<List<AnnouncementModel>>(
          future: _futureAnnouncements,
          builder: (context, snapshot) {
            final unread = snapshot.hasData
                ? snapshot.data!
                      .where((a) => !_acknowledgedIds.contains(a.id))
                      .length
                : 0;
            return Row(
              children: [
                CircleAvatar(
                  radius: 17,
                  backgroundColor: Colors.white24,
                  child: const Icon(
                    Icons.campaign_outlined,
                    color: Colors.white,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Notice Board',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      '$unread unread',
                      style: const TextStyle(
                        fontSize: 11,
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
              ],
            );
          },
        ),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _refresh),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: FutureBuilder<List<AnnouncementModel>>(
          future: _futureAnnouncements,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              return ListView(
                children: [
                  const SizedBox(height: 120),
                  const Icon(Icons.error_outline, color: Colors.grey, size: 32),
                  const SizedBox(height: 12),
                  Center(
                    child: Text(
                      'Could not load notices.\n${snapshot.error}',
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.grey, fontSize: 13),
                    ),
                  ),
                ],
              );
            }

            final notices = snapshot.data ?? [];

            if (notices.isEmpty) {
              return ListView(
                children: const [
                  SizedBox(height: 160),
                  Center(
                    child: Text(
                      'No notices yet.',
                      style: TextStyle(color: Colors.grey, fontSize: 14),
                    ),
                  ),
                ],
              );
            }

            return ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              itemCount: notices.length,
              itemBuilder: (context, index) {
                return _buildNoticeCard(notices[index]);
              },
            );
          },
        ),
      ),
    );
  }

  Widget _buildNoticeCard(AnnouncementModel notice) {
    final isAcknowledged = _acknowledgedIds.contains(notice.id);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(width: 4, color: Colors.grey.shade200),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            notice.title,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              height: 1.35,
                              color: Colors.black87,
                            ),
                          ),
                          if (isAcknowledged)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.grey.shade100,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                'READ',
                                style: TextStyle(
                                  color: Colors.grey.shade500,
                                  fontSize: 9,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.6,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        notice.content,
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade600,
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 14),
                      Divider(color: Colors.grey.shade100, thickness: 1),
                      const SizedBox(height: 6),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              CircleAvatar(
                                radius: 11,
                                backgroundColor: Colors.grey.shade100,
                                child: const Icon(
                                  Icons.person_outline,
                                  size: 13,
                                  color: Colors.grey,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'Admin',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey.shade500,
                                ),
                              ),
                            ],
                          ),
                          _buildAcknowledgeButton(notice),
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
            const SnackBar(
              backgroundColor: Colors.black,
              content: Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.white, size: 18),
                  SizedBox(width: 10),
                  Text(
                    'Announcement acknowledged',
                    style: TextStyle(color: Colors.white),
                  ),
                ],
              ),
            ),
          );
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isAcknowledged ? Colors.white : Colors.black,
          border: Border.all(
            color: isAcknowledged ? Colors.grey.shade300 : Colors.black,
          ),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isAcknowledged ? Icons.check_circle : Icons.circle_outlined,
              size: 14,
              color: isAcknowledged ? Colors.grey.shade500 : Colors.white,
            ),
            const SizedBox(width: 6),
            Text(
              isAcknowledged ? 'Acknowledged' : 'Acknowledge',
              style: TextStyle(
                color: isAcknowledged ? Colors.grey.shade500 : Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
