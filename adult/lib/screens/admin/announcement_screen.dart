import 'package:adult/Model/Announcement_model.dart';
import 'package:adult/core/responsive.dart';
import 'package:flutter/material.dart';
import 'package:adult/screens/color.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:provider/provider.dart';
import 'package:adult/Controller/auth_controller.dart';
import 'package:adult/service/api_config.dart';
import 'package:adult/service/offline_cache.dart';

/// Represents a programme available in the system.
///
/// A programme contains an ID used by the backend and a name
/// displayed to the user.
class ProgrammeModel {
  final int id;
  final String name;

  ProgrammeModel({required this.id, required this.name});

  /// Creates a [ProgrammeModel] from a JSON response.
  factory ProgrammeModel.fromJson(Map<String, dynamic> json) =>
      ProgrammeModel(id: json['id'], name: json['name']?.toString() ?? '');
}

/// Displays announcements available to users.
///
/// This screen is responsible for:
/// - Fetching announcements from the backend.
/// - Searching announcements.
/// - Displaying announcements.
/// - Creating new announcements.
/// - Deleting existing announcements.
/// - Loading programmes for announcement creation.
class AnnouncementsScreen extends StatefulWidget {
  const AnnouncementsScreen({super.key});

  @override
  State<AnnouncementsScreen> createState() => _AnnouncementsScreenState();
}

class _AnnouncementsScreenState extends State<AnnouncementsScreen> {
  // Stores the current search text entered by the user.
  String _searchTerm = '';

  // Future used by FutureBuilder to manage announcement loading.
  late Future<List<AnnouncementModel>> _announcementsFuture;

  @override
  void initState() {
    super.initState();

    // Fetch announcements when the screen is first created.
    _announcementsFuture = _fetchAnnouncements();
  }

  /// Fetches all announcements from the backend API.
  ///
  /// The authentication token is retrieved from [AuthController]
  /// and included in the request Authorization header.
  ///
  /// Throws an [Exception] when the server returns a non-success
  /// status code.
  Future<List<AnnouncementModel>> _fetchAnnouncements() async {
    final token = Provider.of<AuthController>(context, listen: false).token;

    final response = await cachedGet(
      Uri.parse('$kBackendHost/api/announcement/allAnnouncements'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    // Convert the successful API response into AnnouncementModel objects.
    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);

      return data.map((json) => AnnouncementModel.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load announcements: ${response.statusCode}');
    }
  }

  /// Fetches all programmes from the backend.
  ///
  /// Programmes are loaded when creating a new announcement so that
  /// the announcement can be associated with a specific programme.
  Future<List<ProgrammeModel>> _fetchProgrammes() async {
    final token = Provider.of<AuthController>(context, listen: false).token;

    final response = await cachedGet(
      Uri.parse('$kBackendHost/api/programmes/allProgrammes'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);

      return data.map((e) => ProgrammeModel.fromJson(e)).toList();
    }

    throw Exception('Failed to load programmes: ${response.statusCode}');
  }

  /// Reloads announcements from the backend.
  ///
  /// This is called after creating or deleting an announcement
  /// so that the UI displays the latest data.
  void _refreshAnnouncements() {
    setState(() {
      _announcementsFuture = _fetchAnnouncements();
    });
  }

  /// Displays the bottom sheet used to create a new announcement.
  ///
  /// The form collects:
  /// - Announcement title.
  /// - Announcement content.
  /// - Programme associated with the announcement.
  void _showAddModal() {
    final titleCtrl = TextEditingController();
    final contentCtrl = TextEditingController();

    // Stores the programme selected by the user.
    ProgrammeModel? selectedProgramme;

    // Stores programmes loaded from the backend.
    List<ProgrammeModel> programmes = [];

    // Tracks whether programmes are still being loaded.
    bool loadingProgrammes = true;

    // Stores an error message when programme loading fails.
    String? programmeLoadError;

    showAdaptiveSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) {
          // Load programmes when the modal is opened.
          //
          // The boolean prevents the request from being triggered
          // repeatedly whenever the modal rebuilds.
          if (loadingProgrammes) {
            loadingProgrammes = false;

            _fetchProgrammes()
                .then((result) {
                  setModalState(() {
                    programmes = result;
                  });
                })
                .catchError((e) {
                  setModalState(() {
                    programmeLoadError = e.toString();
                  });
                });
          }

          return Container(
            padding: EdgeInsets.only(
              // Prevents the keyboard from covering the form.
              bottom: MediaQuery.of(ctx).viewInsets.bottom,
            ),
            decoration: BoxDecoration(
              color: EduColors.surface,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Modal header containing the title and close button.
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'New Announcement',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                          color: EduColors.textPrimary,
                        ),
                      ),

                      IconButton(
                        onPressed: () => Navigator.pop(ctx),
                        icon: Icon(
                          Icons.close,
                          color: EduColors.textSecondary,
                          size: 22,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Announcement title input.
                  _buildField(
                    titleCtrl,
                    'Title',
                    'Enter announcement title...',
                  ),

                  const SizedBox(height: 14),

                  // Announcement content input.
                  _buildField(
                    contentCtrl,
                    'Content',
                    'Write details here...',
                    maxLines: 4,
                  ),

                  const SizedBox(height: 14),

                  // Programme selection label.
                  Text(
                    'Programme',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: EduColors.textSecondary,
                    ),
                  ),

                  const SizedBox(height: 6),

                  // Display an error message if programmes could not be loaded.
                  if (programmeLoadError != null)
                    Text(
                      'Failed to load programmes',
                      style: TextStyle(
                        color: EduColors.danger,
                        fontSize: 12,
                      ),
                    )
                  else
                    // Allows the user to select the programme
                    // associated with the announcement.
                    DropdownButtonFormField<ProgrammeModel>(
                      value: selectedProgramme,
                      isExpanded: true,
                      hint: Text(
                        programmes.isEmpty
                            ? 'Loading programmes...'
                            : 'Select programme',
                      ),
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: EduColors.background,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 12,
                        ),
                      ),
                      items: programmes
                          .map(
                            (p) =>
                                DropdownMenuItem(value: p, child: Text(p.name)),
                          )
                          .toList(),
                      onChanged: (val) {
                        setModalState(() {
                          selectedProgramme = val;
                        });
                      },
                    ),

                  const SizedBox(height: 24),

                  // Form action buttons.
                  Row(
                    children: [
                      // Closes the modal without creating an announcement.
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(ctx),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 15),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                            side: BorderSide(color: EduColors.textSecondary),
                          ),
                          child: Text(
                            'Cancel',
                            style: TextStyle(
                              color: EduColors.textPrimary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(width: 12),

                      // Creates the announcement.
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () async {
                            debugPrint('POST button tapped');

                            // Validate all required form fields.
                            if (titleCtrl.text.isEmpty ||
                                contentCtrl.text.isEmpty ||
                                selectedProgramme == null) {
                              debugPrint(
                                'Validation failed: '
                                'title="${titleCtrl.text}" '
                                'content="${contentCtrl.text}" '
                                'programme=${selectedProgramme?.id}',
                              );

                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Please fill all fields and pick a programme',
                                  ),
                                ),
                              );

                              return;
                            }

                            try {
                              // Retrieve the authentication token.
                              final token = Provider.of<AuthController>(
                                context,
                                listen: false,
                              ).token;

                              // Send the new announcement to the backend.
                              final response = await http.post(
                                Uri.parse(
                                  '$kBackendHost/api/announcement/addAnnouncement',
                                ),
                                headers: {
                                  'Authorization': 'Bearer $token',
                                  'Content-Type': 'application/json',
                                },
                                body: jsonEncode({
                                  'title': titleCtrl.text,
                                  'content': contentCtrl.text,
                                  'programmeId': selectedProgramme!.id,
                                }),
                              );

                              debugPrint('POST status: ${response.statusCode}');
                              debugPrint('POST body: ${response.body}');

                              // A 200 or 201 response means the announcement
                              // was successfully created.
                              if (response.statusCode == 200 ||
                                  response.statusCode == 201) {
                                Navigator.pop(ctx);

                                // Reload the announcement list.
                                _refreshAnnouncements();
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      'Failed (${response.statusCode}): '
                                      '${response.body}',
                                    ),
                                  ),
                                );
                              }
                            } catch (e) {
                              // Handle network or unexpected errors.
                              debugPrint('Error creating announcement: $e');

                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Error: $e')),
                              );
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: EduColors.primary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 15),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                            elevation: 0,
                          ),
                          child: const Text(
                            'Post',
                            style: TextStyle(fontWeight: FontWeight.w700),
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  /// Builds a reusable text input field.
  ///
  /// [ctrl] controls the input value.
  /// [label] is displayed above the field.
  /// [hint] provides an example or instruction to the user.
  /// [maxLines] controls the height of the text field.
  Widget _buildField(
    TextEditingController ctrl,
    String label,
    String hint, {
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: EduColors.textSecondary,
          ),
        ),

        const SizedBox(height: 6),

        TextField(
          controller: ctrl,
          maxLines: maxLines,
          cursorColor: EduColors.primary,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: Colors.black.withOpacity(0.35)),
            filled: true,
            fillColor: EduColors.background,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 14,
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: EduColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // Header containing the screen title, announcement count,
            // and button for creating a new announcement.
            ResponsiveCenter(child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Text(
                        'Announcements',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: EduColors.textPrimary,
                        ),
                      ),

                      const SizedBox(width: 8),

                      // Displays the number of announcements currently loaded.
                      FutureBuilder<List<AnnouncementModel>>(
                        future: _announcementsFuture,
                        builder: (context, snapshot) {
                          final count = snapshot.data?.length ?? 0;

                          return Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: EduColors.primarySoft,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              '$count',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: EduColors.textPrimary,
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),

                  // Opens the announcement creation modal.
                  HoverCard(child: GestureDetector(
                    onTap: _showAddModal,
                    child: Container(
                      width: 38,
                      height: 38,
                      decoration: const BoxDecoration(
                        color: EduColors.primary,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.add,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  )),
                ],
              ),
            )),

            // Search field used to filter announcements by title or content.
            ResponsiveCenter(child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
              child: TextField(
                onChanged: (v) {
                  setState(() => _searchTerm = v);
                },
                cursorColor: EduColors.primary,
                decoration: InputDecoration(
                  hintText: 'Search updates...',
                  hintStyle: TextStyle(color: Colors.black.withOpacity(0.35)),
                  prefixIcon: Icon(
                    Icons.search,
                    color: EduColors.textSecondary,
                    size: 20,
                  ),
                  filled: true,
                  fillColor: EduColors.background,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            )),

            // Announcement list.
            Expanded(
              child: FutureBuilder<List<AnnouncementModel>>(
                future: _announcementsFuture,
                builder: (context, snapshot) {
                  // Display a loading indicator while announcements
                  // are being retrieved from the backend.
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator(color: EduColors.primary),
                    );
                  }

                  // Display an error message and retry button when
                  // announcement loading fails.
                  if (snapshot.hasError) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.error_outline,
                              color: EduColors.textSecondary,
                              size: 44,
                            ),

                            const SizedBox(height: 12),

                            Text(
                              'Failed to fetch announcements.\n'
                              '${snapshot.error}',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: EduColors.textPrimary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),

                            const SizedBox(height: 16),

                            // Attempts to fetch the announcements again.
                            OutlinedButton(
                              onPressed: _refreshAnnouncements,
                              style: OutlinedButton.styleFrom(
                                side: BorderSide(color: EduColors.textSecondary),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(30),
                                ),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 20,
                                  vertical: 10,
                                ),
                              ),
                              child: Text(
                                'Retry',
                                style: TextStyle(
                                  color: EduColors.textPrimary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  // Filter announcements using the search term.
                  //
                  // Both the title and content are searched.
                  final filtered = (snapshot.data ?? []).where((a) {
                    final term = _searchTerm.toLowerCase();

                    return a.title.toLowerCase().contains(term) ||
                        a.content.toLowerCase().contains(term);
                  }).toList();

                  // Display a message when no announcements match
                  // the search or when there are no announcements.
                  if (filtered.isEmpty) {
                    return Center(
                      child: Text(
                        'No announcements posted.',
                        style: TextStyle(
                          color: EduColors.textSecondary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    );
                  }

                  // One card per announcement, shared by the list and the grid.
                  Widget buildItem(BuildContext context, int index) {
                  final announcement = filtered[index];

                  return Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: EduColors.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: EduColors.border),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Announcement icon.
                        Container(
                          width: 38,
                          height: 38,
                          decoration: BoxDecoration(
                            color: EduColors.primarySoft,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.campaign_outlined,
                            color: EduColors.primary,
                            size: 18,
                          ),
                        ),

                        const SizedBox(width: 12),

                        // Announcement title and content.
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                announcement.title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 14.5,
                                  fontWeight: FontWeight.w700,
                                  color: EduColors.textPrimary,
                                ),
                              ),

                              const SizedBox(height: 4),

                              Text(
                                announcement.content,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 13,
                                  height: 1.35,
                                  color: EduColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Deletes the selected announcement.
                        IconButton(
                          onPressed: () async {
                            try {
                              // Retrieve the authentication token.
                              final token = Provider.of<AuthController>(
                                context,
                                listen: false,
                              ).token;

                              // Send the delete request to the backend.
                              await http.delete(
                                Uri.parse(
                                  '$kBackendHost/api/announcement/delete/${announcement.id}',
                                ),
                                headers: {'Authorization': 'Bearer $token'},
                              );

                              // Refresh the list after deletion.
                              _refreshAnnouncements();
                            } catch (e) {
                              debugPrint('Error deleting announcement: $e');
                            }
                          },
                          icon: Icon(
                            Icons.delete_outline,
                            color: EduColors.textSecondary,
                            size: 19,
                          ),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                      ],
                    ),
                  );
                    }

                  if (!context.isMobile) {
                    return CenteredScrollPadding(
                      padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
                      builder: (context, padding) => SingleChildScrollView(
                        padding: padding,
                        child: ResponsiveGrid(
                          spacing: 10,
                          runSpacing: 10,
                          children: [
                            for (var i = 0; i < filtered.length; i++)
                              buildItem(context, i),
                          ],
                        ),
                      ),
                    );
                  }

                  // Display the filtered announcements.
                  return ListView.separated(
                    padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
                    itemCount: filtered.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: buildItem,
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
