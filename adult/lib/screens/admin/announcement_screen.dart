import 'package:adult/Model/Announcement_model.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:provider/provider.dart';
import 'package:adult/Controller/auth_controller.dart';

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

    final response = await http.get(
      Uri.parse('http://10.0.2.2:8080/api/announcement/allAnnouncements'),
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

    final response = await http.get(
      Uri.parse('http://10.0.2.2:8080/api/programmes/allProgrammes'),
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

    showModalBottomSheet(
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
            decoration: const BoxDecoration(
              color: Colors.white,
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
                      const Text(
                        'New Announcement',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                          color: Colors.black,
                        ),
                      ),

                      IconButton(
                        onPressed: () => Navigator.pop(ctx),
                        icon: const Icon(
                          Icons.close,
                          color: Colors.black54,
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
                  const Text(
                    'Programme',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: Colors.black54,
                    ),
                  ),

                  const SizedBox(height: 6),

                  // Display an error message if programmes could not be loaded.
                  if (programmeLoadError != null)
                    Text(
                      'Failed to load programmes',
                      style: TextStyle(
                        color: Colors.red.shade700,
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
                        fillColor: const Color(0xFFF5F5F5),
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
                            side: const BorderSide(color: Colors.black26),
                          ),
                          child: const Text(
                            'Cancel',
                            style: TextStyle(
                              color: Colors.black,
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
                                  'http://10.0.2.2:8080/api/announcement/addAnnouncement',
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
                            backgroundColor: Colors.black,
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
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: Colors.black54,
          ),
        ),

        const SizedBox(height: 6),

        TextField(
          controller: ctrl,
          maxLines: maxLines,
          cursorColor: Colors.black,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: Colors.black.withOpacity(0.35)),
            filled: true,
            fillColor: const Color(0xFFF5F5F5),
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
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // Header containing the screen title, announcement count,
            // and button for creating a new announcement.
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Text(
                        'Announcements',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: Colors.black,
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
                              color: const Color(0xFFF0F0F0),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              '$count',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: Colors.black,
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),

                  // Opens the announcement creation modal.
                  GestureDetector(
                    onTap: _showAddModal,
                    child: Container(
                      width: 38,
                      height: 38,
                      decoration: const BoxDecoration(
                        color: Colors.black,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.add,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Search field used to filter announcements by title or content.
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
              child: TextField(
                onChanged: (v) {
                  setState(() => _searchTerm = v);
                },
                cursorColor: Colors.black,
                decoration: InputDecoration(
                  hintText: 'Search updates...',
                  hintStyle: TextStyle(color: Colors.black.withOpacity(0.35)),
                  prefixIcon: const Icon(
                    Icons.search,
                    color: Colors.black45,
                    size: 20,
                  ),
                  filled: true,
                  fillColor: const Color(0xFFF5F5F5),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),

            // Announcement list.
            Expanded(
              child: FutureBuilder<List<AnnouncementModel>>(
                future: _announcementsFuture,
                builder: (context, snapshot) {
                  // Display a loading indicator while announcements
                  // are being retrieved from the backend.
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator(color: Colors.black),
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
                            const Icon(
                              Icons.error_outline,
                              color: Colors.black45,
                              size: 44,
                            ),

                            const SizedBox(height: 12),

                            Text(
                              'Failed to fetch announcements.\n'
                              '${snapshot.error}',
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: Colors.black87,
                                fontWeight: FontWeight.w600,
                              ),
                            ),

                            const SizedBox(height: 16),

                            // Attempts to fetch the announcements again.
                            OutlinedButton(
                              onPressed: _refreshAnnouncements,
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(color: Colors.black26),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(30),
                                ),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 20,
                                  vertical: 10,
                                ),
                              ),
                              child: const Text(
                                'Retry',
                                style: TextStyle(
                                  color: Colors.black,
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
                          color: Colors.grey.shade500,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    );
                  }

                  // Display the filtered announcements.
                  return ListView.separated(
                    padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
                    itemCount: filtered.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final announcement = filtered[index];

                      return Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFFEDEDED)),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Announcement icon.
                            Container(
                              width: 38,
                              height: 38,
                              decoration: BoxDecoration(
                                color: const Color(0xFFF0F0F0),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(
                                Icons.campaign_outlined,
                                color: Colors.black,
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
                                    style: const TextStyle(
                                      fontSize: 14.5,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.black,
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
                                      color: Colors.grey.shade600,
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
                                      'http://10.0.2.2:8080/api/announcement/delete/${announcement.id}',
                                    ),
                                    headers: {'Authorization': 'Bearer $token'},
                                  );

                                  // Refresh the list after deletion.
                                  _refreshAnnouncements();
                                } catch (e) {
                                  debugPrint('Error deleting announcement: $e');
                                }
                              },
                              icon: const Icon(
                                Icons.delete_outline,
                                color: Colors.black38,
                                size: 19,
                              ),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                            ),
                          ],
                        ),
                      );
                    },
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
