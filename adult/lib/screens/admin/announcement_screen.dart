import 'package:adult/Model/Announcement_model.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:provider/provider.dart';
import 'package:adult/Controller/auth_controller.dart';

class ProgrammeModel {
  final int id;
  final String name;
  ProgrammeModel({required this.id, required this.name});
  factory ProgrammeModel.fromJson(Map<String, dynamic> json) =>
      ProgrammeModel(id: json['id'], name: json['name']?.toString() ?? '');
}

class AnnouncementsScreen extends StatefulWidget {
  const AnnouncementsScreen({super.key});

  @override
  State<AnnouncementsScreen> createState() => _AnnouncementsScreenState();
}

class _AnnouncementsScreenState extends State<AnnouncementsScreen> {
  String _searchTerm = '';
  late Future<List<AnnouncementModel>> _announcementsFuture;

  @override
  void initState() {
    super.initState();
    _announcementsFuture = _fetchAnnouncements();
  }

  Future<List<AnnouncementModel>> _fetchAnnouncements() async {
    final token = Provider.of<AuthController>(context, listen: false).token;

    final response = await http.get(
      Uri.parse('http://10.0.2.2:8080/api/announcement/allAnnouncements'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return data.map((json) => AnnouncementModel.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load announcements: ${response.statusCode}');
    }
  }

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

  void _refreshAnnouncements() {
    setState(() {
      _announcementsFuture = _fetchAnnouncements();
    });
  }

  void _showAddModal() {
    final titleCtrl = TextEditingController();
    final contentCtrl = TextEditingController();
    ProgrammeModel? selectedProgramme;
    List<ProgrammeModel> programmes = [];
    bool loadingProgrammes = true;
    String? programmeLoadError;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) {
          if (loadingProgrammes) {
            loadingProgrammes = false; // guard: only kick off the fetch once
            _fetchProgrammes()
                .then((result) {
                  setModalState(() => programmes = result);
                })
                .catchError((e) {
                  setModalState(() => programmeLoadError = e.toString());
                });
          }

          return Container(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(ctx).viewInsets.bottom,
            ),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              border: Border(top: BorderSide(color: Colors.black, width: 2)),
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
                        'NEW ANNOUNCEMENT',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.2,
                          color: Colors.black,
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(ctx),
                        icon: const Icon(
                          Icons.close,
                          color: Colors.black,
                          size: 24,
                        ),
                      ),
                    ],
                  ),
                  const Divider(color: Colors.black, thickness: 1.5),
                  const SizedBox(height: 16),
                  _buildField(
                    titleCtrl,
                    'TITLE',
                    'Enter announcement title...',
                  ),
                  const SizedBox(height: 16),
                  _buildField(
                    contentCtrl,
                    'CONTENT',
                    'Write details here...',
                    maxLines: 4,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'PROGRAMME',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.0,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 6),
                  if (programmeLoadError != null)
                    Text(
                      'Failed to load programmes',
                      style: TextStyle(
                        color: Colors.red.shade700,
                        fontSize: 12,
                      ),
                    )
                  else
                    DropdownButtonFormField<ProgrammeModel>(
                      value: selectedProgramme,
                      isExpanded: true,
                      hint: Text(
                        programmes.isEmpty
                            ? 'Loading programmes...'
                            : 'Select programme',
                      ),
                      decoration: const InputDecoration(
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.zero,
                          borderSide: BorderSide(
                            color: Colors.black,
                            width: 1.5,
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.zero,
                          borderSide: BorderSide(
                            color: Colors.black,
                            width: 1.5,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.zero,
                          borderSide: BorderSide(
                            color: Colors.black,
                            width: 2.5,
                          ),
                        ),
                        contentPadding: EdgeInsets.symmetric(
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
                      onChanged: (val) =>
                          setModalState(() => selectedProgramme = val),
                    ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(ctx),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: const RoundedRectangleBorder(
                              borderRadius: BorderRadius.zero,
                            ),
                            side: const BorderSide(
                              color: Colors.black,
                              width: 2,
                            ),
                          ),
                          child: const Text(
                            'CANCEL',
                            style: TextStyle(
                              color: Colors.black,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.1,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () async {
                            if (titleCtrl.text.isNotEmpty &&
                                contentCtrl.text.isNotEmpty &&
                                selectedProgramme != null) {
                              try {
                                final token = Provider.of<AuthController>(
                                  context,
                                  listen: false,
                                ).token;
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
                                if (response.statusCode == 200 ||
                                    response.statusCode == 201) {
                                  Navigator.pop(ctx);
                                  _refreshAnnouncements();
                                }
                              } catch (e) {
                                debugPrint('Error creating announcement: $e');
                              }
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Please fill all fields and pick a programme',
                                  ),
                                ),
                              );
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.black,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: const RoundedRectangleBorder(
                              borderRadius: BorderRadius.zero,
                            ),
                            elevation: 0,
                          ),
                          child: const Text(
                            'POST',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.1,
                            ),
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
            fontWeight: FontWeight.bold,
            letterSpacing: 1.0,
            color: Colors.black,
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: ctrl,
          maxLines: maxLines,
          cursorColor: Colors.black,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: Colors.black.withOpacity(0.4)),
            filled: true,
            fillColor: Colors.white,
            border: const OutlineInputBorder(
              borderRadius: BorderRadius.zero,
              borderSide: BorderSide(color: Colors.black, width: 1.5),
            ),
            enabledBorder: const OutlineInputBorder(
              borderRadius: BorderRadius.zero,
              borderSide: BorderSide(color: Colors.black, width: 1.5),
            ),
            focusedBorder: const OutlineInputBorder(
              borderRadius: BorderRadius.zero,
              borderSide: BorderSide(color: Colors.black, width: 2.5),
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
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: FutureBuilder<List<AnnouncementModel>>(
          future: _announcementsFuture,
          builder: (context, snapshot) {
            final count = snapshot.data?.length ?? 0;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'ANNOUNCEMENTS',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.5,
                    color: Colors.black,
                  ),
                ),
                Text(
                  '$count updates posted',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.black,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            );
          },
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: IconButton(
              onPressed: _showAddModal,
              icon: const Icon(Icons.add, color: Colors.black, size: 28),
            ),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(2.0),
          child: Container(color: Colors.black, height: 2.0),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: TextField(
                onChanged: (v) => setState(() => _searchTerm = v),
                cursorColor: Colors.black,
                decoration: InputDecoration(
                  hintText: 'Search updates...',
                  hintStyle: TextStyle(color: Colors.black.withOpacity(0.4)),
                  prefixIcon: const Icon(Icons.search, color: Colors.black),
                  filled: true,
                  fillColor: Colors.white,
                  border: const OutlineInputBorder(
                    borderRadius: BorderRadius.zero,
                    borderSide: BorderSide(color: Colors.black, width: 1.5),
                  ),
                  enabledBorder: const OutlineInputBorder(
                    borderRadius: BorderRadius.zero,
                    borderSide: BorderSide(color: Colors.black, width: 1.5),
                  ),
                  focusedBorder: const OutlineInputBorder(
                    borderRadius: BorderRadius.zero,
                    borderSide: BorderSide(color: Colors.black, width: 2.5),
                  ),
                  contentPadding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
            Expanded(
              child: FutureBuilder<List<AnnouncementModel>>(
                future: _announcementsFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator(color: Colors.black),
                    );
                  }

                  if (snapshot.hasError) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.error_outline,
                              color: Colors.black,
                              size: 44,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'Failed to fetch announcements.\n${snapshot.error}',
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: Colors.black,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 16),
                            OutlinedButton(
                              onPressed: _refreshAnnouncements,
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(
                                  color: Colors.black,
                                  width: 1.5,
                                ),
                                shape: const RoundedRectangleBorder(
                                  borderRadius: BorderRadius.zero,
                                ),
                              ),
                              child: const Text(
                                'RETRY',
                                style: TextStyle(color: Colors.black),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  final filtered = (snapshot.data ?? []).where((a) {
                    final term = _searchTerm.toLowerCase();
                    return a.title.toLowerCase().contains(term) ||
                        a.content.toLowerCase().contains(term);
                  }).toList();

                  if (filtered.isEmpty) {
                    return const Center(
                      child: Text(
                        'No announcements posted.',
                        style: TextStyle(
                          color: Colors.black,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    );
                  }

                  return ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    itemCount: filtered.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final announcement = filtered[index];
                      return Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          border: Border.all(color: Colors.black, width: 2),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Padding(
                              padding: EdgeInsets.only(top: 3.0),
                              child: Icon(
                                Icons.campaign_outlined,
                                color: Colors.black,
                                size: 24,
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    announcement.title.toUpperCase(),
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    announcement.content,
                                    style: const TextStyle(
                                      fontSize: 13,
                                      height: 1.4,
                                      color: Colors.black,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            IconButton(
                              onPressed: () async {
                                try {
                                  final token = Provider.of<AuthController>(
                                    context,
                                    listen: false,
                                  ).token;
                                  await http.delete(
                                    Uri.parse(
                                      'http://10.0.2.2:8080/api/announcement/delete/${announcement.id}',
                                    ),
                                    headers: {'Authorization': 'Bearer $token'},
                                  );
                                  _refreshAnnouncements();
                                } catch (e) {
                                  debugPrint('Error deleting announcement: $e');
                                }
                              },
                              icon: const Icon(
                                Icons.delete_sharp,
                                color: Colors.black,
                                size: 20,
                              ),
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
