import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../Controller/auth_controller.dart';
import 'package:adult/service/sync_service.dart';
import 'package:adult/service/user_profile_service.dart';
import 'package:adult/screens/color.dart'; // EduColors (same import as AccountDetailsPage)
import 'package:adult/screens/account_settings.dart'; // adjust if the file name differs

/// Displays application settings for the current user.
///
/// The screen provides:
/// - Profile information.
/// - Notification preferences.
/// - Navigation to the Account Details page.
/// - Logout functionality.
class NotificationPage extends StatefulWidget {
  const NotificationPage({super.key});

  @override
  State<NotificationPage> createState() => _NotificationPageState();
}

class _NotificationPageState extends State<NotificationPage> {
  // Stores whether application notifications are currently enabled.
  bool _notificationsEnabled = true;

  // Bumped after editing account details so the profile card reloads
  // from local storage and shows the new values.
  int _profileVersion = 0;

  Future<void> _openAccountDetails() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const AccountDetailsPage()),
    );
    if (mounted) setState(() => _profileVersion++);
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
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _ProfileCard(key: ValueKey(_profileVersion)),
                    const SizedBox(height: 26),

                    // ── Preferences ──────────────────────────────────
                    _sectionLabel('Preferences'),
                    const SizedBox(height: 10),
                    _SettingsCard(
                      children: [
                        _ToggleTile(
                          icon: Icons.notifications_none_rounded,
                          tint: EduColors.accentSoft,
                          fg: EduColors.accent,
                          title: 'Notifications',
                          subtitle: 'Receive alerts for new notices',
                          value: _notificationsEnabled,
                          onChanged: (val) =>
                              setState(() => _notificationsEnabled = val),
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    // ── Account ──────────────────────────────────────
                    _sectionLabel('Account'),
                    const SizedBox(height: 10),
                    _SettingsCard(
                      children: [
                        _ActionTile(
                          icon: Icons.person_outline_rounded,
                          tint: EduColors.primarySoft,
                          fg: EduColors.primary,
                          title: 'Account Details',
                          subtitle: 'Update your name, email & photo',
                          onTap: _openAccountDetails,
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    // ── Danger zone ──────────────────────────────────
                    _sectionLabel('Danger zone'),
                    const SizedBox(height: 10),
                    _SettingsCard(
                      children: [
                        _ActionTile(
                          icon: Icons.logout_rounded,
                          tint: const Color(0xFFFDECEC),
                          fg: EduColors.danger,
                          title: 'Logout',
                          subtitle: 'Sign out of your account',
                          destructive: true,
                          onTap: () => _confirmLogout(context),
                        ),
                      ],
                    ),

                    const SizedBox(height: 28),

                    const Center(
                      child: Text(
                        'Adult Education App · v1.0.0',
                        style: TextStyle(
                          fontSize: 11,
                          color: EduColors.textSecondary,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

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
                  'Settings',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: EduColors.textPrimary,
                    letterSpacing: -0.3,
                  ),
                ),
                Text(
                  'Manage your account',
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

  /// Builds a section heading.
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

  /// Displays a confirmation dialog before logging out.
  ///
  /// If the user confirms, the authentication controller performs the
  /// logout and the user is redirected to the login page.
  Future<void> _confirmLogout(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: EduColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text(
          'Logout',
          style: TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 18,
            color: EduColors.textPrimary,
          ),
        ),
        content: const Text(
          'Are you sure you want to sign out?',
          style: TextStyle(
            fontSize: 14,
            height: 1.4,
            color: EduColors.textSecondary,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text(
              'Cancel',
              style: TextStyle(
                color: EduColors.textSecondary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: EduColors.danger,
              foregroundColor: EduColors.onPrimary,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: const Text('Logout'),
          ),
        ],
      ),
    );

    // Only perform logout when the user confirms.
    if (confirm == true && context.mounted) {
      final navigator = Navigator.of(context);
      // Don't leave the previous user's details on the device.
      await UserProfileService(db: context.read<SyncService>().db).clear();
      if (!context.mounted) return;
      await context.read<AuthController>().logout();

      // Remove previous navigation history and send the user back
      // to the login screen. (Change '/login' if you use a welcome route.)
      if (navigator.mounted) {
        navigator.pushNamedAndRemoveUntil('/login', (route) => false);
      }
    }
  }
}

/// Displays the signed-in user's profile information, loaded from the
/// local database (falls back to the AuthController's email).
class _ProfileCard extends StatefulWidget {
  const _ProfileCard({super.key});

  @override
  State<_ProfileCard> createState() => _ProfileCardState();
}

class _ProfileCardState extends State<_ProfileCard> {
  UserProfile? _profile;
  bool _loaded = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_loaded) {
      _loaded = true;
      _load();
    }
  }

  Future<void> _load() async {
    final profile =
    await UserProfileService(db: context.read<SyncService>().db).getCurrent();
    if (!mounted) return;
    setState(() => _profile = profile);
  }

  @override
  Widget build(BuildContext context) {
    final fallbackEmail =
        context.read<AuthController>().currentUser?.email ?? '';
    final profile = _profile ?? UserProfile(email: fallbackEmail);

    final hasName = profile.fullName.isNotEmpty;
    final title = hasName
        ? profile.fullName
        : (profile.email.isEmpty ? 'Your account' : profile.email);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [EduColors.primary, EduColors.primaryDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [
          BoxShadow(
            color: Color(0x403D5CFF),
            blurRadius: 24,
            offset: Offset(0, 12),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 60,
            height: 60,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              color: EduColors.onPrimaryFaint,
              shape: BoxShape.circle,
            ),
            child: Text(
              profile.initials,
              style: const TextStyle(
                color: EduColors.onPrimary,
                fontWeight: FontWeight.w800,
                fontSize: 20,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: EduColors.onPrimary,
                  ),
                ),
                if (hasName && profile.email.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    profile.email,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 12,
                      color: EduColors.onPrimaryMuted,
                    ),
                  ),
                ],
                const SizedBox(height: 8),
                Container(
                  padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: EduColors.accent,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    profile.isAdmin ? 'Admin' : 'Student',
                    style: const TextStyle(
                      color: EduColors.onPrimary,
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Provides a reusable card container for settings items.
class _SettingsCard extends StatelessWidget {
  final List<Widget> children;

  const _SettingsCard({required this.children});

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
        // Material so the InkWell ripple shows inside the card.
        child: Material(
          color: EduColors.surface,
          child: Column(children: children),
        ),
      ),
    );
  }
}

/// Displays a settings item containing a switch.
class _ToggleTile extends StatelessWidget {
  final IconData icon;
  final Color tint;
  final Color fg;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _ToggleTile({
    required this.icon,
    required this.tint,
    required this.fg,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: tint,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, size: 22, color: fg),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: EduColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 11.5,
                    color: EduColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Switch.adaptive(
            value: value,
            onChanged: onChanged,
            activeTrackColor: EduColors.primary,
          ),
        ],
      ),
    );
  }
}

/// Displays an action that can be tapped by the user.
///
/// [destructive] changes the styling to indicate a potentially
/// destructive operation such as logout.
class _ActionTile extends StatelessWidget {
  final IconData icon;
  final Color tint;
  final Color fg;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final bool destructive;

  const _ActionTile({
    required this.icon,
    required this.tint,
    required this.fg,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.destructive = false,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      splashColor: tint,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: tint,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, size: 22, color: fg),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: destructive
                          ? EduColors.danger
                          : EduColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 11.5,
                      color: EduColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                color: destructive
                    ? const Color(0xFFFDECEC)
                    : EduColors.primarySoft,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.chevron_right_rounded,
                size: 20,
                color: destructive ? EduColors.danger : EduColors.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}