import 'package:adult/core/admin_table.dart';
import 'package:adult/core/responsive.dart';
import 'package:flutter/material.dart';
import 'package:adult/screens/color.dart';
import 'package:adult/Model/user_model.dart';
import 'package:adult/Service/user_service.dart';

class StudentsScreen extends StatefulWidget {
  const StudentsScreen({super.key});

  @override
  State<StudentsScreen> createState() => _StudentsScreenState();
}

class _StudentsScreenState extends State<StudentsScreen> {
  final TextEditingController _searchController = TextEditingController();
  final UserService _userService = UserService();
  String _searchTerm = '';
  late Future<List<UserModel>> _studentsFuture;

  @override
  void initState() {
    super.initState();
    _studentsFuture = _userService.getStudentsByInstitution();
  }

  void _refreshStudents() {
    setState(() {
      _studentsFuture = _userService.getStudentsByInstitution();
    });
  }

  void _showAddModal() {
    final nameCtrl = TextEditingController();
    final emailCtrl = TextEditingController();

    showAdaptiveSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        decoration: BoxDecoration(
          color: EduColors.surface,
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
                  Text(
                    'Add New Student',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: EduColors.textPrimary,
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(ctx),
                    icon: Icon(Icons.close, color: EduColors.textSecondary),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _ModalField(
                controller: nameCtrl,
                label: 'Full Name',
                hint: 'Enter student name',
                accentColor: EduColors.textPrimary,
              ),
              const SizedBox(height: 12),
              _ModalField(
                controller: emailCtrl,
                label: 'Email',
                hint: 'student@email.com',
                accentColor: EduColors.textPrimary,
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
                        side: BorderSide(color: EduColors.border),
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
                      onPressed: () async {
                        if (nameCtrl.text.isNotEmpty &&
                            emailCtrl.text.isNotEmpty) {
                          try {
                            final password = await _userService.addStudent(
                              nameCtrl.text,
                              emailCtrl.text,
                            );
                            if (!ctx.mounted) return;
                            Navigator.pop(ctx);
                            _refreshStudents();
                            await showDialog<void>(
                              context: context,
                              builder: (d) => AlertDialog(
                                title: const Text('Student added'),
                                content: SelectableText(
                                  'Give ${nameCtrl.text} these sign-in details:\n\n'
                                  'Email: ${emailCtrl.text.trim()}\n'
                                  'Temporary password: $password\n\n'
                                  'They can change the password in Account settings.',
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(d),
                                    child: const Text('Done'),
                                  ),
                                ],
                              ),
                            );
                          } catch (e) {
                            if (!ctx.mounted) return;
                            ScaffoldMessenger.of(ctx).showSnackBar(
                              SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
                            );
                          }
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: EduColors.primary,
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

  Widget _studentCard(UserModel s) {
    return Container(
      padding: const EdgeInsets.all(16),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        s.fullName,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: EduColors.textPrimary,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    _statusChip(s),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(
                      Icons.mail_outline,
                      size: 14,
                      color: EduColors.textSecondary,
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        s.email,
                        style: TextStyle(
                          fontSize: 13,
                          color: EduColors.textSecondary,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                if (s.programmeName != null &&
                    s.programmeName!.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Icon(
                        Icons.school_outlined,
                        size: 14,
                        color: EduColors.textSecondary,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          s.programmeName!,
                          style: TextStyle(
                            fontSize: 13,
                            color: EduColors.textSecondary,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          _deleteButton(s),
        ],
      ),
    );
  }

  Widget _statusChip(UserModel s) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 8,
        vertical: 2,
      ),
      decoration: BoxDecoration(
        color: s.isActive
            ? const Color(0xFFDCFCE7)
            : EduColors.border,
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
              : EduColors.textSecondary,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _deleteButton(UserModel s) {
    return IconButton(
      tooltip: 'Deactivate',
      onPressed: () async {
        final ok = await showDialog<bool>(
          context: context,
          builder: (d) => AlertDialog(
            title: const Text('Deactivate this student?'),
            content: const Text(
              'They will no longer be able to sign in. Their grades and '
              'history are kept, and you can reactivate them under More → Users.',
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(d, false), child: const Text('Cancel')),
              FilledButton(onPressed: () => Navigator.pop(d, true), child: const Text('Deactivate')),
            ],
          ),
        );
        if (ok != true) return;
        await _userService.deleteStudent(s.id!);
        _refreshStudents();
      },
      icon: const Icon(
        Icons.person_off_outlined,
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
                  FutureBuilder<List<UserModel>>(
                    future: _studentsFuture,
                    builder: (context, snapshot) {
                      final count = snapshot.data?.length ?? 0;
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Students',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w700,
                              color: EduColors.textPrimary,
                            ),
                          ),
                          Text(
                            '$count total students',
                            style: TextStyle(
                              fontSize: 13,
                              color: EduColors.textSecondary,
                            ),
                          ),
                        ],
                      );
                    },
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
              padding: const EdgeInsets.all(16),
              child: TextField(
                controller: _searchController,
                onChanged: (v) => setState(() => _searchTerm = v),
                decoration: InputDecoration(
                  hintText: 'Search students...',
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
                    borderSide: const BorderSide(
                      color: EduColors.primary,
                      width: 2,
                    ),
                  ),
                  contentPadding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            )),
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
                          Icon(
                            Icons.wifi_off,
                            color: EduColors.textSecondary,
                            size: 48,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Could not load students.\n${snapshot.error}',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: EduColors.textSecondary),
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
                    return Center(
                      child: Text(
                        'No students found.',
                        style: TextStyle(color: EduColors.textSecondary),
                      ),
                    );
                  }

                  if (context.isDesktop) {
                    return CenteredScrollPadding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                      builder: (context, padding) => AdminDataTable(
                        padding: padding,
                        columns: const [
                          DataColumn(label: Text('Name')),
                          DataColumn(label: Text('Email')),
                          DataColumn(label: Text('Programme')),
                          DataColumn(label: Text('Status')),
                          DataColumn(label: Text('')),
                        ],
                        rows: [
                          for (final s in filtered)
                            DataRow(cells: [
                              DataCell(TableText(s.fullName,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w600))),
                              DataCell(TableText(s.email)),
                              DataCell(TableText((s.programmeName ?? '').isEmpty
                                  ? '-'
                                  : s.programmeName!)),
                              DataCell(_statusChip(s)),
                              DataCell(_deleteButton(s)),
                            ]),
                        ],
                      ),
                    );
                  }
                  if (context.isTablet) {
                    return CenteredScrollPadding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                      builder: (context, padding) => SingleChildScrollView(
                        padding: padding,
                        child: ResponsiveGrid(
                          spacing: 10,
                          runSpacing: 10,
                          children: [for (final s in filtered) _studentCard(s)],
                        ),
                      ),
                    );
                  }
                  return ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    itemCount: filtered.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      return _studentCard(filtered[index]);
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
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: EduColors.textPrimary,
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
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
