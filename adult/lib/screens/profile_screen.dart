import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:adult/Model/lms_models.dart';
import 'package:adult/screens/color.dart';
import 'package:adult/screens/lms_widgets.dart';
import 'package:adult/service/accessibility_settings.dart';
import 'package:adult/service/lms_api.dart';

/// The learner's own profile: personal details, education level, and
/// reading preferences (text size, data saver).
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return LmsPage(
      title: 'My Profile',
      body: AsyncView<List<dynamic>>(
        load: () => Future.wait([
          LmsApi.get('/profile'),
          LmsApi.get('/profile/education-levels'),
        ]),
        builder: (context, data, reload) => _ProfileForm(
          profile: Profile.fromJson(data[0] as Map<String, dynamic>),
          levels: (data[1] as List).cast<String>(),
        ),
      ),
    );
  }
}

class _ProfileForm extends StatefulWidget {
  final Profile profile;
  final List<String> levels;
  const _ProfileForm({required this.profile, required this.levels});

  @override
  State<_ProfileForm> createState() => _ProfileFormState();
}

class _ProfileFormState extends State<_ProfileForm> {
  final _form = GlobalKey<FormState>();
  late final _first = TextEditingController(text: widget.profile.firstName);
  late final _last = TextEditingController(text: widget.profile.lastName);
  late final _phone = TextEditingController(text: widget.profile.phoneNumber ?? '');
  late final _address = TextEditingController(text: widget.profile.address ?? '');
  late final _occupation = TextEditingController(text: widget.profile.occupation ?? '');
  late String? _gender = widget.profile.gender;
  late String? _level = widget.profile.educationLevel;
  late DateTime? _dob = widget.profile.dateOfBirth == null ? null : DateTime.tryParse(widget.profile.dateOfBirth!);
  bool _saving = false;

  @override
  void dispose() {
    for (final c in [_first, _last, _phone, _address, _occupation]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      await LmsApi.put('/profile', {
        'firstName': _first.text,
        'lastName': _last.text,
        'phoneNumber': _phone.text,
        'address': _address.text,
        'occupation': _occupation.text,
        'gender': _gender ?? '',
        'educationLevel': _level ?? '',
        'dateOfBirth': _dob == null ? '' : _dob!.toIso8601String().substring(0, 10),
      });
      if (mounted) showMessage(context, 'Profile saved');
    } catch (e) {
      if (mounted) showError(context, e);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _pickDob() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _dob ?? DateTime(1985),
      firstDate: DateTime(1920),
      lastDate: DateTime.now(),
      helpText: 'Date of birth',
    );
    if (picked != null) setState(() => _dob = picked);
  }

  InputDecoration _field(String label, IconData icon) => InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        filled: true,
        fillColor: EduColors.surface,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
      );

  @override
  Widget build(BuildContext context) {
    final p = widget.profile;
    final a11y = context.watch<AccessibilitySettings>();
    return Form(
      key: _form,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          LmsCard(
            child: Row(children: [
              CircleAvatar(
                radius: 30,
                backgroundColor: EduColors.primarySoft,
                child: Text(
                  p.firstName.isNotEmpty ? p.firstName[0].toUpperCase() : '?',
                  style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: EduColors.primary),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(p.fullName, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                  Text(p.email, style: TextStyle(color: EduColors.textSecondary)),
                  const SizedBox(height: 4),
                  Wrap(spacing: 6, runSpacing: 4, children: [
                    StatusChip(roleLabel(p.role), color: EduColors.primary),
                    if (p.programmeName != null) StatusChip(p.programmeName!, color: EduColors.accent),
                  ]),
                ]),
              ),
            ]),
          ),
          const SectionTitle('Personal details'),
          TextFormField(
            controller: _first,
            decoration: _field('First name', Icons.person_outline),
            validator: (v) => (v ?? '').trim().isEmpty ? 'Enter your first name' : null,
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _last,
            decoration: _field('Last name', Icons.person_outline),
            validator: (v) => (v ?? '').trim().isEmpty ? 'Enter your last name' : null,
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _phone,
            keyboardType: TextInputType.phone,
            decoration: _field('Phone number', Icons.phone_outlined),
          ),
          const SizedBox(height: 12),
          InkWell(
            onTap: _pickDob,
            child: InputDecorator(
              decoration: _field('Date of birth', Icons.cake_outlined),
              child: Text(_dob == null ? 'Tap to choose' : formatDate(_dob)),
            ),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            initialValue: _gender != null && ['Female', 'Male', 'Prefer not to say'].contains(_gender) ? _gender : null,
            decoration: _field('Gender', Icons.wc_outlined),
            items: const ['Female', 'Male', 'Prefer not to say']
                .map((g) => DropdownMenuItem(value: g, child: Text(g)))
                .toList(),
            onChanged: (v) => setState(() => _gender = v),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _address,
            maxLines: 2,
            decoration: _field('Home address', Icons.home_outlined),
          ),
          const SectionTitle('Education'),
          DropdownButtonFormField<String>(
            initialValue: widget.levels.contains(_level) ? _level : null,
            isExpanded: true,
            decoration: _field('Highest education level', Icons.school_outlined),
            items: widget.levels.map((l) => DropdownMenuItem(value: l, child: Text(l))).toList(),
            onChanged: (v) => setState(() => _level = v),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _occupation,
            decoration: _field('Occupation / work', Icons.work_outline),
          ),
          const SizedBox(height: 20),
          BigButton(label: 'Save profile', icon: Icons.save_rounded, busy: _saving, onPressed: _save),
          const SectionTitle('Reading'),
          LmsCard(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('Text size', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              SegmentedButton<double>(
                segments: const [
                  ButtonSegment(value: 1.0, label: Text('Normal')),
                  ButtonSegment(value: 1.2, label: Text('Large')),
                  ButtonSegment(value: 1.4, label: Text('Extra large')),
                ],
                selected: {a11y.textScale},
                onSelectionChanged: (s) => a11y.setTextScale(s.first),
              ),
            ]),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}
