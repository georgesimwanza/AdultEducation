import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:adult/Model/user_model.dart';
import 'package:shared_preferences/shared_preferences.dart'; // add this import

class StudentsScreen extends StatefulWidget {
  const StudentsScreen({super.key});

  @override
  State<StudentsScreen> createState() => _StudentsScreenState();
}

class _StudentsScreenState extends State<StudentsScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchTerm = '';
  late Future<List<UserModel>> _studentsFuture;

  @override
  void initState() {
    super.initState();
    _studentsFuture = fetchStudents();
  }

  Future<Map<String, String>> _authHeaders() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token') ?? '';
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  Future<List<UserModel>> fetchStudents() async {
    try {
      final response = await http.get(
        Uri.parse('http://10.0.2.2:8080/api/users/AllStudents'),
        headers: await _authHeaders(),
      );
      print('Status: ${response.statusCode}');
      print('Body: ${response.body}');
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((json) => UserModel.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load students: ${response.statusCode}');
      }
    } catch (e) {
      rethrow;
    }
  }

  void _refreshStudents() {
    setState(() {
      _studentsFuture = fetchStudents();
    });
  }

  void _showAddModal() {
    final nameCtrl = TextEditingController();
    final emailCtrl = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
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
                    'Add New Student',
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
              _ModalField(
                controller: nameCtrl,
                label: 'Full Name',
                hint: 'Enter student name',
                accentColor: const Color.fromARGB(255, 0, 0, 0),
              ),
              const SizedBox(height: 12),
              _ModalField(
                controller: emailCtrl,
                label: 'Email',
                hint: 'student@email.com',
                accentColor: const Color.fromARGB(255, 0, 0, 0),
                keyboardType: TextInputType.emailAddress,
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
                      onPressed: () async {
                        if (nameCtrl.text.isNotEmpty &&
                            emailCtrl.text.isNotEmpty) {
                          try {
                            final parts = nameCtrl.text.trim().split(' ');
                            final response = await http.post(
                              Uri.parse(
                                'http://10.0.2.2:8080/api/users/AllStudents',
                              ),
                              headers: {'Content-Type': 'application/json'},
                              body: jsonEncode({
                                'firstName': parts.first,
                                'lastName': parts.length > 1
                                    ? parts.skip(1).join(' ')
                                    : '',
                                'email': emailCtrl.text,
                              }),
                            );
                            if (response.statusCode == 200 ||
                                response.statusCode == 201) {
                              Navigator.pop(ctx);
                              _refreshStudents();
                            }
                          } catch (e) {
                            print('Error adding student: $e');
                          }
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
                        'Add Student',
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
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // ── Header ──────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  FutureBuilder<List<UserModel>>(
                    future: _studentsFuture,
                    builder: (context, snapshot) {
                      final count = snapshot.data?.length ?? 0;
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Students',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF111827),
                            ),
                          ),
                          Text(
                            '$count total students',
                            style: const TextStyle(
                              fontSize: 13,
                              color: Color(0xFF6B7280),
                            ),
                          ),
                        ],
                      );
                    },
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
                            color: Color(0x333B82F6),
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
              padding: const EdgeInsets.all(16),
              child: TextField(
                controller: _searchController,
                onChanged: (v) => setState(() => _searchTerm = v),
                decoration: InputDecoration(
                  hintText: 'Search students...',
                  hintStyle: const TextStyle(color: Color(0xFF9CA3AF)),
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

            // ── Student list ─────────────────────────────────────────
            Expanded(
              child: FutureBuilder<List<UserModel>>(
                future: _studentsFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (snapshot.hasError) {
                    return Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.wifi_off,
                            color: Color(0xFF9CA3AF),
                            size: 48,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Could not load students.\n${snapshot.error}',
                            textAlign: TextAlign.center,
                            style: const TextStyle(color: Color(0xFF6B7280)),
                          ),
                          const SizedBox(height: 12),
                          ElevatedButton(
                            onPressed: _refreshStudents,
                            child: const Text('Retry'),
                          ),
                        ],
                      ),
                    );
                  }

                  final filtered = (snapshot.data ?? []).where((s) {
                    final term = _searchTerm.toLowerCase();
                    return s.fullName.toLowerCase().contains(term) ||
                        s.email.toLowerCase().contains(term);
                  }).toList();

                  if (filtered.isEmpty) {
                    return const Center(
                      child: Text(
                        'No students found.',
                        style: TextStyle(color: Color(0xFF6B7280)),
                      ),
                    );
                  }

                  return ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    itemCount: filtered.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final s = filtered[index];
                      return Container(
                        padding: const EdgeInsets.all(16),
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
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Name + active badge
                                  Row(
                                    children: [
                                      Text(
                                        s.fullName,
                                        style: const TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w600,
                                          color: Color(0xFF111827),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 2,
                                        ),
                                        decoration: BoxDecoration(
                                          color: s.isActive
                                              ? const Color(0xFFDCFCE7)
                                              : const Color(0xFFF3F4F6),
                                          borderRadius: BorderRadius.circular(
                                            20,
                                          ),
                                        ),
                                        child: Text(
                                          s.status,
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: s.isActive
                                                ? const Color(0xFF15803D)
                                                : const Color(0xFF6B7280),
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  // Email
                                  Row(
                                    children: [
                                      const Icon(
                                        Icons.mail_outline,
                                        size: 14,
                                        color: Color(0xFF9CA3AF),
                                      ),
                                      const SizedBox(width: 4),
                                      Expanded(
                                        child: Text(
                                          s.email,
                                          style: const TextStyle(
                                            fontSize: 13,
                                            color: Color(0xFF6B7280),
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 2),
                                  // Programme
                                  if (s.programmeName != null &&
                                      s.programmeName!.isNotEmpty)
                                    Row(
                                      children: [
                                        const Icon(
                                          Icons.school_outlined,
                                          size: 14,
                                          color: Color(0xFF9CA3AF),
                                        ),
                                        const SizedBox(width: 4),
                                        Expanded(
                                          child: Text(
                                            s.programmeName!,
                                            style: const TextStyle(
                                              fontSize: 13,
                                              color: Color(0xFF6B7280),
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    ),
                                ],
                              ),
                            ),
                            // Delete
                            IconButton(
                              onPressed: () async {
                                try {
                                  await http.delete(
                                    Uri.parse(
                                      'http://10.0.2.2:8080/api/users/AllStudents/${s.id}',
                                    ),
                                  );
                                  _refreshStudents();
                                } catch (e) {
                                  print('Error deleting student: $e');
                                }
                              },
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

class _ModalField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  final Color accentColor;
  final TextInputType? keyboardType;

  const _ModalField({
    required this.controller,
    required this.label,
    required this.hint,
    required this.accentColor,
    this.keyboardType,
  });

  @override
  Widget build(BuildContext context) {
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
          controller: controller,
          keyboardType: keyboardType,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: Color(0xFF9CA3AF)),
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
              borderSide: BorderSide(color: accentColor, width: 2),
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
}
