import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:adult/screens/color.dart'; // EduColors
import 'package:adult/service/account_service.dart';
import 'package:adult/service/sync_service.dart';
import 'package:adult/service/user_profile_service.dart';

class AccountDetailsPage extends StatefulWidget {
  const AccountDetailsPage({super.key});

  @override
  State<AccountDetailsPage> createState() => _AccountDetailsPageState();
}

class _AccountDetailsPageState extends State<AccountDetailsPage> {
  final _formKey = GlobalKey<FormState>();
  bool _isSaving = false;
  bool _currentVisible = false;
  bool _passwordVisible = false;
  bool _confirmVisible = false;

  // Controllers — prefilled from the local database in _loadProfile().
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();

  UserProfile? _profile;
  bool _profileLoaded = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_profileLoaded) {
      _profileLoaded = true;
      _loadProfile();
    }
  }

  Future<void> _loadProfile() async {
    final profile =
    await UserProfileService(db: context.read<SyncService>().db).getCurrent();
    if (!mounted || profile == null) return;
    setState(() {
      _profile = profile;
      _nameController.text = profile.fullName;
      _emailController.text = profile.email;
      _phoneController.text = profile.phone ?? '';
    });
  }

  final _currentPasswordController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _currentPasswordController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  /// Up to two initials from the name field, updated as the user types.
  String get _initials {
    final parts = _nameController.text
        .trim()
        .split(RegExp(r'\s+'))
        .where((p) => p.isNotEmpty)
        .toList();
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts.first[0].toUpperCase();
    return (parts.first[0] + parts.last[0]).toUpperCase();
  }

  void _showMessage(
      ScaffoldMessengerState messenger,
      String text, {
        bool isError = false,
      }) {
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(
                isError
                    ? Icons.error_outline_rounded
                    : Icons.check_circle_rounded,
                color: isError ? EduColors.danger : EduColors.success,
                size: 18,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  text,
                  style: const TextStyle(color: EduColors.onPrimary),
                ),
              ),
            ],
          ),
          backgroundColor: EduColors.textPrimary,
          behavior: SnackBarBehavior.floating,
          shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          margin: const EdgeInsets.all(12),
        ),
      );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    setState(() => _isSaving = true);

    // Read everything we need from `context` before any await.
    final service = UserProfileService(db: context.read<SyncService>().db);
    final messenger = ScaffoldMessenger.of(context);

    final changingPassword = _passwordController.text.isNotEmpty;

    // The password lives on the server, so change it there first. If that
    // fails (wrong current password, offline, ...) nothing else is saved and
    // the user can fix it and tap Save again.
    if (changingPassword) {
      try {
        await AccountService().changePassword(
          currentPassword: _currentPasswordController.text,
          newPassword: _passwordController.text,
        );
      } on AccountException catch (e) {
        if (!mounted) return;
        setState(() => _isSaving = false);
        _showMessage(messenger, e.message, isError: true);
        return;
      }
    }

    final parts = _nameController.text.trim().split(RegExp(r'\s+'));
    final firstName = parts.first;
    final lastName = parts.length > 1 ? parts.sublist(1).join(' ') : '';

    final base = _profile ?? UserProfile(email: _emailController.text.trim());
    final updated = base.copyWith(
      email: _emailController.text.trim(),
      firstName: firstName,
      lastName: lastName,
      phone: _phoneController.text.trim(),
    );

    // Saved locally first so every page shows the change immediately,
    // marked "not synced" until it's pushed to the server.
    await service.saveLocalEdit(updated);

    // TODO: push the name / email / phone changes to the server, then mark
    // the local row as synced. (Password is already handled above.)

    if (!mounted) return;
    setState(() {
      _isSaving = false;
      _profile = updated.copyWith(synced: false);
    });

    if (changingPassword) {
      _currentPasswordController.clear();
      _passwordController.clear();
      _confirmController.clear();
    }

    _showMessage(
      messenger,
      changingPassword
          ? 'Password updated. Other changes saved on this device'
          : 'Changes saved on this device',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: EduColors.background,
      body: SafeArea(
        child: Column(
          children: [
            _buildTopBar(),
            Expanded(
              child: Form(
                key: _formKey,
                child: SingleChildScrollView(
                  keyboardDismissBehavior:
                  ScrollViewKeyboardDismissBehavior.onDrag,
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildAvatar(),
                      const SizedBox(height: 26),

                      // ── Personal info ───────────────────────────────
                      _sectionLabel('Personal info'),
                      const SizedBox(height: 10),
                      _FormCard(
                        children: [
                          _buildField(
                            controller: _nameController,
                            label: 'Full name',
                            icon: Icons.person_outline_rounded,
                            tint: EduColors.primarySoft,
                            fg: EduColors.primary,
                            onChanged: (_) => setState(() {}),
                            validator: (v) => v == null || v.trim().isEmpty
                                ? 'Name is required'
                                : null,
                          ),
                          _cardDivider(),
                          _buildField(
                            controller: _emailController,
                            label: 'Email address',
                            icon: Icons.mail_outline_rounded,
                            tint: EduColors.accentSoft,
                            fg: EduColors.accent,
                            keyboardType: TextInputType.emailAddress,
                            validator: (v) {
                              if (v == null || v.trim().isEmpty) {
                                return 'Email is required';
                              }
                              if (!v.contains('@')) {
                                return 'Enter a valid email';
                              }
                              return null;
                            },
                          ),
                          _cardDivider(),
                          _buildField(
                            controller: _phoneController,
                            label: 'Phone number',
                            icon: Icons.phone_outlined,
                            tint: EduColors.successSoft,
                            fg: EduColors.success,
                            keyboardType: TextInputType.phone,
                            validator: (v) => v == null || v.trim().isEmpty
                                ? 'Phone is required'
                                : null,
                          ),
                        ],
                      ),

                      const SizedBox(height: 24),

                      // ── Change password ─────────────────────────────
                      _sectionLabel('Change password'),
                      const SizedBox(height: 4),
                      const Padding(
                        padding: EdgeInsets.only(left: 4, bottom: 10),
                        child: Text(
                          'Leave blank to keep your current password. '
                              'Changing it needs your current password and '
                              'an internet connection.',
                          style: TextStyle(
                            fontSize: 11.5,
                            height: 1.4,
                            color: EduColors.textSecondary,
                          ),
                        ),
                      ),
                      _FormCard(
                        children: [
                          _buildField(
                            controller: _currentPasswordController,
                            label: 'Current password',
                            icon: Icons.lock_open_rounded,
                            tint: EduColors.primarySoft,
                            fg: EduColors.primary,
                            obscure: !_currentVisible,
                            suffixIcon: _eyeButton(
                              visible: _currentVisible,
                              onTap: () => setState(
                                      () => _currentVisible = !_currentVisible),
                            ),
                            validator: (v) {
                              if (_passwordController.text.isNotEmpty &&
                                  (v == null || v.isEmpty)) {
                                return 'Enter your current password';
                              }
                              return null;
                            },
                          ),
                          _cardDivider(),
                          _buildField(
                            controller: _passwordController,
                            label: 'New password',
                            icon: Icons.lock_outline_rounded,
                            tint: EduColors.primarySoft,
                            fg: EduColors.primary,
                            obscure: !_passwordVisible,
                            suffixIcon: _eyeButton(
                              visible: _passwordVisible,
                              onTap: () => setState(
                                      () => _passwordVisible = !_passwordVisible),
                            ),
                            validator: (v) {
                              if (v == null || v.isEmpty) return null;
                              if (v.length < 8) {
                                return 'Password must be at least 8 characters';
                              }
                              if (v == _currentPasswordController.text) {
                                return 'Choose a different password';
                              }
                              return null;
                            },
                          ),
                          _cardDivider(),
                          _buildField(
                            controller: _confirmController,
                            label: 'Confirm password',
                            icon: Icons.lock_reset_rounded,
                            tint: EduColors.primarySoft,
                            fg: EduColors.primary,
                            obscure: !_confirmVisible,
                            suffixIcon: _eyeButton(
                              visible: _confirmVisible,
                              onTap: () => setState(
                                      () => _confirmVisible = !_confirmVisible),
                            ),
                            validator: (v) {
                              if (_passwordController.text.isNotEmpty &&
                                  v != _passwordController.text) {
                                return 'Passwords do not match';
                              }
                              return null;
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
            _buildSaveBar(),
          ],
        ),
      ),
    );
  }

  // ── Pieces ─────────────────────────────────────────────────────────────

  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
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
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Account details',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: EduColors.textPrimary,
                    letterSpacing: -0.3,
                  ),
                ),
                Text(
                  'Update your profile',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: EduColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAvatar() {
    return Center(
      child: Column(
        children: [
          Stack(
            children: [
              Container(
                width: 96,
                height: 96,
                alignment: Alignment.center,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [EduColors.primary, EduColors.primaryDark],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Color(0x403D5CFF),
                      blurRadius: 20,
                      offset: Offset(0, 8),
                    ),
                  ],
                ),
                child: Text(
                  _initials,
                  style: const TextStyle(
                    color: EduColors.onPrimary,
                    fontSize: 32,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: GestureDetector(
                  onTap: () {
                    // TODO: image picker
                  },
                  child: Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: EduColors.accent,
                      shape: BoxShape.circle,
                      border: Border.all(color: EduColors.background, width: 3),
                    ),
                    child: const Icon(
                      Icons.camera_alt_rounded,
                      size: 16,
                      color: EduColors.onPrimary,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          const Text(
            'Change photo',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: EduColors.primary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSaveBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
      decoration: const BoxDecoration(
        color: EduColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: Color(0x143D5CFF),
            blurRadius: 20,
            offset: Offset(0, -6),
          ),
        ],
      ),
      child: SizedBox(
        width: double.infinity,
        height: 54,
        child: ElevatedButton(
          onPressed: _isSaving ? null : _save,
          style: ElevatedButton.styleFrom(
            backgroundColor: EduColors.primary,
            foregroundColor: EduColors.onPrimary,
            disabledBackgroundColor: const Color(0x993D5CFF),
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(27),
            ),
          ),
          child: _isSaving
              ? const SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(
              strokeWidth: 2.5,
              color: EduColors.onPrimary,
            ),
          )
              : const Text(
            'Save changes',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
          ),
        ),
      ),
    );
  }

  Widget _eyeButton({required bool visible, required VoidCallback onTap}) {
    return IconButton(
      icon: Icon(
        visible ? Icons.visibility_outlined : Icons.visibility_off_outlined,
        size: 20,
        color: EduColors.textSecondary,
      ),
      onPressed: onTap,
    );
  }

  Widget _sectionLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w800,
          color: EduColors.textPrimary,
        ),
      ),
    );
  }

  Widget _cardDivider() => const Divider(
    height: 1,
    thickness: 1,
    color: EduColors.border,
    indent: 16,
    endIndent: 16,
  );

  Widget _buildField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required Color tint,
    required Color fg,
    TextInputType keyboardType = TextInputType.text,
    bool obscure = false,
    Widget? suffixIcon,
    ValueChanged<String>? onChanged,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscure,
      validator: validator,
      onChanged: onChanged,
      cursorColor: EduColors.primary,
      style: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: EduColors.textPrimary,
      ),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(
          fontSize: 13,
          color: EduColors.textSecondary,
        ),
        floatingLabelStyle: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w700,
          color: fg,
        ),
        prefixIcon: Padding(
          padding: const EdgeInsets.all(10),
          child: Container(
            width: 34,
            decoration: BoxDecoration(
              color: tint,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 18, color: fg),
          ),
        ),
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: EduColors.surface,
        border: InputBorder.none,
        enabledBorder: InputBorder.none,
        focusedBorder: InputBorder.none,
        contentPadding:
        const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        errorStyle: const TextStyle(fontSize: 11, color: EduColors.danger),
      ),
    );
  }
}

// ─── Form card wrapper ───────────────────────────────────────────────────────

class _FormCard extends StatelessWidget {
  final List<Widget> children;
  const _FormCard({required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: EduColors.surface,
        borderRadius: BorderRadius.circular(22),
        boxShadow: EduColors.cardShadow,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: Column(children: children),
      ),
    );
  }
}