import 'package:adult/service/announcement_service.dart';
import 'package:flutter/material.dart';
import 'package:adult/Model/Announcement_model.dart';

/// Displays announcements retrieved for the current
/// institution and programme.
///
/// Users can:
/// - View available announcements.
/// - Refresh the announcement list.
/// - Mark announcements as acknowledged.
///
/// Acknowledgement is currently stored only in memory,
/// so it is reset when the application restarts.
class NoticeBoardScreen extends StatefulWidget {
  const NoticeBoardScreen({super.key});

  @override
  State<NoticeBoardScreen> createState() => _NoticeBoardScreenState();
}

class _NoticeBoardScreenState extends State<NoticeBoardScreen> {
  // Service responsible for retrieving announcements
  // from the backend.
  final AnnouncementService _service = AnnouncementService();

  // Stores the future used to load announcements.
  //
  // FutureBuilder uses this value to manage loading,
  // success, and error states.
  late Future<List<AnnouncementModel>> _futureAnnouncements;

  // Stores the IDs of announcements acknowledged by
  // the current user during the current app session.
  //
  // This is local-only because AnnouncementModel/backend
  // does not currently contain an acknowledgement field.
  //
  // For persistent acknowledgement, this could later be
  // stored in SharedPreferences or the backend.
  final Set<int> _acknowledgedIds = {};

  @override
  void initState() {
    super.initState();

    // Load announcements when the screen is first created.
    _futureAnnouncements = _loadAnnouncements();
  }

  /// Retrieves announcements associated with the
  /// institution and programme stored in preferences.
  Future<List<AnnouncementModel>> _loadAnnouncements() {
    return _service.getByInstitutionAndProgrammeFromPrefs();
  }

  /// Refreshes the announcement list.
  ///
  /// A new Future is assigned so that FutureBuilder
  /// performs the request again.
  Future<void> _refresh() async {
    setState(() {
      _futureAnnouncements = _loadAnnouncements();
    });

    // Wait for the refreshed data to finish loading.
    await _futureAnnouncements;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),

      // Application bar containing the screen title,
      // unread count, and refresh action.
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        titleSpacing: 0,

        // Allows the user to return to the previous screen.
        leading: const BackButton(),

        title: FutureBuilder<List<AnnouncementModel>>(
          future: _futureAnnouncements,
          builder: (context, snapshot) {
            // Count announcements that have not been
            // acknowledged during this session.
            final unread = snapshot.hasData
                ? snapshot.data!
                      .where((a) => !_acknowledgedIds.contains(a.id))
                      .length
                : 0;

            return Row(
              children: [
                // Announcement icon.
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

                // Notice board title and unread count.
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
          // Allows the user to manually refresh
          // the announcement list.
          IconButton(icon: const Icon(Icons.refresh), onPressed: _refresh),
        ],
      ),

      // RefreshIndicator provides pull-to-refresh functionality.
      body: RefreshIndicator(
        onRefresh: _refresh,

        child: FutureBuilder<List<AnnouncementModel>>(
          future: _futureAnnouncements,
          builder: (context, snapshot) {
            // Display a loading indicator while
            // announcements are being retrieved.
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            // Display an error message if the request fails.
            if (snapshot.hasError) {
              return ListView(
                children: [
                  const SizedBox(height: 120),

                  const Icon(Icons.error_outline, color: Colors.grey, size: 32),

                  const SizedBox(height: 12),

                  Center(
                    child: Text(
                      'Could not load notices.\n'
                      '${snapshot.error}',
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.grey, fontSize: 13),
                    ),
                  ),
                ],
              );
            }

            // Use an empty list when the API does not
            // return any announcements.
            final notices = snapshot.data ?? [];

            // Display an empty-state message when
            // there are no announcements.
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

            // Build a scrollable list of announcements.
            return ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              itemCount: notices.length,

              itemBuilder: (context, index) {
                // Build the card for the current announcement.
                return _buildNoticeCard(notices[index]);
              },
            );
          },
        ),
      ),
    );
  }

  /// Builds the visual card used to display an announcement.
  ///
  /// The card shows:
  /// - Announcement title.
  /// - Announcement content.
  /// - Administrator information.
  /// - Acknowledgement status.
  Widget _buildNoticeCard(AnnouncementModel notice) {
    // Determine whether this announcement has already
    // been acknowledged during the current session.
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
              // Small vertical accent on the left side.
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
                          // Announcement title.
                          Text(
                            notice.title,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              height: 1.35,
                              color: Colors.black87,
                            ),
                          ),

                          // Show a READ badge when the
                          // announcement has been acknowledged.
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

                      // Announcement message.
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
                          // Display the announcement author.
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

                          // Button used to acknowledge the announcement.
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

  /// Builds the acknowledgement button for an announcement.
  ///
  /// Tapping the button toggles the announcement between
  /// acknowledged and unacknowledged states.
  Widget _buildAcknowledgeButton(AnnouncementModel notice) {
    final isAcknowledged = _acknowledgedIds.contains(notice.id);

    return GestureDetector(
      onTap: () => setState(() {
        // Remove the ID if the announcement was already acknowledged.
        if (isAcknowledged) {
          _acknowledgedIds.remove(notice.id);
        }
        // Otherwise add the announcement ID to the
        // acknowledged set.
        else {
          _acknowledgedIds.add(notice.id);
        }
      }),

      // AnimatedContainer smoothly changes the
      // button appearance when its state changes.
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

