import 'package:flutter/material.dart';

import 'package:adult/Model/lms_models.dart';
import 'package:adult/screens/color.dart';
import 'package:adult/screens/lms_widgets.dart';
import 'package:adult/screens/progress_report_screen.dart';
import 'package:adult/service/lms_api.dart';

/// Admin account management: create learner/instructor/admin accounts,
/// change roles, and deactivate or reactivate accounts.
class UsersScreen extends StatefulWidget {
  const UsersScreen({super.key});

  @override
  State<UsersScreen> createState() => _UsersScreenState();
}

class _UsersScreenState extends State<UsersScreen> {
  final _view = GlobalKey<AsyncViewState<List<Profile>>>();
  String _filter = 'ALL';
  String _search = '';

  Future<void> _create() async {
    final created = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (_) => const _CreateUserSheet(),
    );
    if (created == true) _view.currentState?.reload();
  }

  Future<void> _manage(Profile u) async {
    final action = await showModalBottomSheet<String>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          ListTile(
            title: Text(u.fullName, style: const TextStyle(fontWeight: FontWeight.w800)),
            subtitle: Text('${u.email} · ${roleLabel(u.role)}'),
          ),
          const Divider(height: 1),
          if (u.role == 'USER')
            ListTile(
              leading: const Icon(Icons.insights_rounded),
              title: const Text('View progress report'),
              onTap: () => Navigator.pop(ctx, 'report'),
            ),
          for (final r in ['USER', 'INSTRUCTOR', 'ADMIN'].where((r) => r != u.role))
            ListTile(
              leading: const Icon(Icons.badge_rounded),
              title: Text('Make ${roleLabel(r).toLowerCase()}'),
              onTap: () => Navigator.pop(ctx, 'role:$r'),
            ),
          ListTile(
            leading: Icon(u.isActive ? Icons.block_rounded : Icons.check_circle_rounded,
                color: u.isActive ? EduColors.danger : EduColors.success),
            title: Text(u.isActive ? 'Deactivate account' : 'Reactivate account'),
            subtitle: Text(u.isActive ? 'They will not be able to sign in. Their records are kept.' : ''),
            onTap: () => Navigator.pop(ctx, 'toggle'),
          ),
        ]),
      ),
    );
    if (action == null || !mounted) return;
    if (action == 'report') {
      Navigator.push(context, MaterialPageRoute(builder: (_) => ProgressReportScreen(learnerId: u.id)));
      return;
    }
    try {
      if (action == 'toggle') {
        await LmsApi.patch('/admin/users/${u.id}/status', {'active': !u.isActive});
        if (mounted) showMessage(context, u.isActive ? '${u.fullName} deactivated' : '${u.fullName} reactivated');
      } else if (action.startsWith('role:')) {
        final role = action.substring(5);
        await LmsApi.patch('/admin/users/${u.id}/role', {'role': role});
        if (mounted) showMessage(context, '${u.fullName} is now ${roleLabel(role).toLowerCase()}');
      }
      _view.currentState?.reload();
    } catch (e) {
      if (mounted) showError(context, e);
    }
  }

  @override
  Widget build(BuildContext context) {
    return LmsPage(
      title: 'Users',
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _create,
        backgroundColor: EduColors.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.person_add_rounded),
        label: const Text('Add user'),
      ),
      body: AsyncView<List<Profile>>(
        key: _view,
        load: () async => ((await LmsApi.get('/admin/users')) as List).map((e) => Profile.fromJson(e)).toList(),
        builder: (context, users, reload) {
          final shown = users.where((u) {
            final roleOk = _filter == 'ALL' ||
                (_filter == 'INACTIVE' ? !u.isActive : u.role == _filter || (_filter == 'ADMIN' && u.role == 'INSTITUTION'));
            final q = _search.toLowerCase();
            return roleOk && (q.isEmpty || u.fullName.toLowerCase().contains(q) || u.email.toLowerCase().contains(q));
          }).toList();
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 90),
            children: [
              TextField(
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.search_rounded),
                  hintText: 'Search by name or email',
                  filled: true,
                  fillColor: EduColors.surface,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                ),
                onChanged: (v) => setState(() => _search = v),
              ),
              const SizedBox(height: 10),
              Wrap(spacing: 8, runSpacing: 6, children: [
                for (final (key, label) in [
                  ('ALL', 'All (${users.length})'),
                  ('USER', 'Learners'),
                  ('INSTRUCTOR', 'Instructors'),
                  ('ADMIN', 'Admins'),
                  ('INACTIVE', 'Deactivated'),
                ])
                  ChoiceChip(
                    label: Text(label),
                    selected: _filter == key,
                    onSelected: (_) => setState(() => _filter = key),
                  ),
              ]),
              const SizedBox(height: 12),
              if (shown.isEmpty) const Padding(padding: EdgeInsets.all(24), child: Text('No users match.')),
              for (final u in shown)
                LmsCard(
                  onTap: () => _manage(u),
                  child: Row(children: [
                    CircleAvatar(
                      backgroundColor: u.isActive ? EduColors.primarySoft : EduColors.border,
                      child: Text(u.firstName.isNotEmpty ? u.firstName[0].toUpperCase() : '?',
                          style: const TextStyle(fontWeight: FontWeight.w800)),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(u.fullName,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: u.isActive ? EduColors.textPrimary : EduColors.textSecondary,
                            )),
                        Text(u.email, style: const TextStyle(color: EduColors.textSecondary)),
                        Text(
                          [
                            if (u.educationLevel != null) u.educationLevel!,
                            'last sign-in ${u.lastLoginAt == null ? 'never' : relativeTime(u.lastLoginAt!)}',
                          ].join(' · '),
                          style: const TextStyle(fontSize: 12.5, color: EduColors.textSecondary),
                        ),
                      ]),
                    ),
                    Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                      StatusChip(roleLabel(u.role), color: EduColors.primary),
                      if (!u.isActive) ...[
                        const SizedBox(height: 4),
                        const StatusChip('Deactivated', color: EduColors.danger),
                      ],
                    ]),
                  ]),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _CreateUserSheet extends StatefulWidget {
  const _CreateUserSheet();

  @override
  State<_CreateUserSheet> createState() => _CreateUserSheetState();
}

class _CreateUserSheetState extends State<_CreateUserSheet> {
  final _form = GlobalKey<FormState>();
  final _first = TextEditingController();
  final _last = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  String _role = 'USER';
  bool _busy = false;

  @override
  void dispose() {
    for (final c in [_first, _last, _email, _password]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    setState(() => _busy = true);
    try {
      await LmsApi.post('/admin/users', {
        'firstName': _first.text.trim(),
        'lastName': _last.text.trim(),
        'email': _email.text.trim(),
        'password': _password.text,
        'role': _role,
      });
      if (mounted) {
        showMessage(context, 'Account created');
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) showError(context, e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    InputDecoration deco(String label) =>
        InputDecoration(labelText: label, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)));
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(context).viewInsets.bottom + 20),
      child: Form(
        key: _form,
        child: SingleChildScrollView(
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            const Text('Add a user', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
            const SizedBox(height: 14),
            SegmentedButton<String>(
              segments: const [
                ButtonSegment(value: 'USER', label: Text('Learner')),
                ButtonSegment(value: 'INSTRUCTOR', label: Text('Instructor')),
                ButtonSegment(value: 'ADMIN', label: Text('Admin')),
              ],
              selected: {_role},
              onSelectionChanged: (s) => setState(() => _role = s.first),
            ),
            const SizedBox(height: 12),
            TextFormField(
                controller: _first,
                decoration: deco('First name'),
                validator: (v) => (v ?? '').trim().isEmpty ? 'Required' : null),
            const SizedBox(height: 10),
            TextFormField(
                controller: _last,
                decoration: deco('Last name'),
                validator: (v) => (v ?? '').trim().isEmpty ? 'Required' : null),
            const SizedBox(height: 10),
            TextFormField(
              controller: _email,
              keyboardType: TextInputType.emailAddress,
              decoration: deco('Email'),
              validator: (v) => (v ?? '').contains('@') ? null : 'Enter a valid email',
            ),
            const SizedBox(height: 10),
            TextFormField(
              controller: _password,
              decoration: deco('Starting password (8+ characters)'),
              validator: (v) => (v ?? '').length < 8 ? 'At least 8 characters' : null,
            ),
            const SizedBox(height: 18),
            BigButton(label: 'Create account', icon: Icons.person_add_rounded, busy: _busy, onPressed: _save),
          ]),
        ),
      ),
    );
  }
}
