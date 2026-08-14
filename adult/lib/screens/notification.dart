import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../Controller/auth_controller.dart';

/// Displays application settings for the current user.
///
/// The screen currently provides:
/// - Profile information.
/// - Notification preferences.
/// - Account details navigation placeholder.
/// - Logout functionality.
class NotificationPage extends StatefulWidget {
  const NotificationPage({super.key});

  @override
  State<NotificationPage> createState() => _NotificationPageState();
}

class _NotificationPageState extends State<NotificationPage> {
  // Stores whether application notifications
  // are currently enabled.
  bool _notificationsEnabled = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),

      // Settings page header.
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        titleSpacing: 0,

        // Allows the user to return to the previous page.
        leading: const BackButton(),

        title: Row(
          children: [
            // Settings icon.
            CircleAvatar(
              radius: 17,
              backgroundColor: Colors.white24,
              child: const Icon(
                Icons.settings_outlined,
                color: Colors.white,
                size: 18,
              ),
            ),

            const SizedBox(width: 10),

            // Settings title and description.
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Settings',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                ),

                Text(
                  'Manage your account',
                  style: TextStyle(fontSize: 11, color: Colors.white70),
                ),
              ],
            ),
          ],
        ),
      ),

      // Scrollable settings content.
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),

        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,

          children: [
            // Profile information card.
            _ProfileCard(),

            const SizedBox(height: 20),

            // Preferences section.
            _sectionLabel('Preferences'),

            const SizedBox(height: 8),

            // Notification settings.
            _SettingsCard(
              children: [
                _ToggleTile(
                  icon: Icons.notifications_outlined,
                  title: 'Notifications',
                  subtitle: 'Receive alerts for new notices',

                  // Current notification state.
                  value: _notificationsEnabled,

                  // Update notification state when
                  // the switch is changed.
                  onChanged: (val) =>
                      setState(() => _notificationsEnabled = val),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Account section.
            _sectionLabel('Account'),

            const SizedBox(height: 8),

            _SettingsCard(
              children: [
                _ActionTile(
                  icon: Icons.person_outline,
                  title: 'Account Details',
                  subtitle: 'Update your name, email & photo',

                  // Account details navigation is
                  // currently a placeholder.
                  onTap: () {
                    // TODO: navigate to account details page
                  },
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Destructive account actions.
            _sectionLabel('Danger zone'),

            const SizedBox(height: 8),

            _SettingsCard(
              children: [
                _ActionTile(
                  icon: Icons.logout,
                  title: 'Logout',
                  subtitle: 'Sign out of your account',
                  destructive: true,

                  // Show a confirmation dialog before logging out.
                  onTap: () => _confirmLogout(context),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Application version information.
            Center(
              child: Text(
                'Adult Education App · v1.0.0',
                style: TextStyle(fontSize: 11, color: Colors.grey.shade400),
              ),
            ),

            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  /// Builds a small uppercase section heading.
  Widget _sectionLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),

      child: Text(
        label.toUpperCase(),

        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.1,
          color: Colors.grey.shade500,
        ),
      ),
    );
  }

  /// Displays a confirmation dialog before logging out.
  ///
  /// If the user confirms, the authentication controller
  /// performs the logout and the user is redirected to
  /// the login page.
  Future<void> _confirmLogout(BuildContext context) async {
    // Display the confirmation dialog.
    final confirm = await showDialog<bool>(
      context: context,

      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),

        title: const Text(
          'Logout',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),

        content: const Text('Are you sure you want to sign out?'),

        actions: [
          // Cancel the logout operation.
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),

            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),

          // Confirm logout.
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),

            child: const Text(
              'Logout',
              style: TextStyle(color: Colors.red, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );

    // Only perform logout when the user confirms.
    if (confirm == true && context.mounted) {
      // Clear authentication state through
      // the application's AuthController.
      await context.read<AuthController>().logout();

      // Remove previous navigation history and
      // send the user back to the login screen.
      Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
    }
  }
}

/// Displays the user's profile information.
class _ProfileCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),

      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
      ),

      child: Row(
        children: [
          // User avatar.
          CircleAvatar(
            radius: 28,
            backgroundColor: Colors.black,

            child: const Text(
              'GS',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 16,
              ),
            ),
          ),

          const SizedBox(width: 14),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,

              children: [
                // User name.
                const Text(
                  'George Simwanza',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                ),

                const SizedBox(height: 2),

                // User email.
                Text(
                  'george@zuco.ac.zm',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                ),

                const SizedBox(height: 6),

                // User role badge.
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),

                  decoration: BoxDecoration(
                    color: Colors.black,
                    borderRadius: BorderRadius.circular(6),
                  ),

                  child: const Text(
                    'Student',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.6,
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
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
      ),

      // Allows multiple settings items to be
      // displayed inside the same card.
      child: Column(children: children),
    );
  }
}

/// Displays a settings item containing a switch.
///
/// This widget is reusable for boolean preferences
/// such as notification settings.
class _ToggleTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _ToggleTile({
    required this.icon,
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
          // Settings icon.
          Container(
            width: 38,
            height: 38,

            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(10),
            ),

            child: Icon(icon, size: 20, color: Colors.black87),
          ),

          const SizedBox(width: 14),

          // Setting title and description.
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,

              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),

                const SizedBox(height: 1),

                Text(
                  subtitle,
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                ),
              ],
            ),
          ),

          // Switch used to change the setting.
          Switch.adaptive(
            value: value,
            onChanged: onChanged,
            activeColor: Colors.black,
          ),
        ],
      ),
    );
  }
}

/// Displays an action that can be tapped by the user.
///
/// [destructive] changes the styling to indicate a
/// potentially destructive operation such as logout.
class _ActionTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final bool destructive;

  const _ActionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.destructive = false,
  });

  @override
  Widget build(BuildContext context) {
    // Use red for destructive actions and black
    // for normal actions.
    final color = destructive ? Colors.red : Colors.black87;

    return InkWell(
      onTap: onTap,

      borderRadius: BorderRadius.circular(14),

      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),

        child: Row(
          children: [
            // Action icon.
            Container(
              width: 38,
              height: 38,

              decoration: BoxDecoration(
                color: destructive ? Colors.red.shade50 : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(10),
              ),

              child: Icon(icon, size: 20, color: color),
            ),

            const SizedBox(width: 14),

            // Action title and description.
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,

                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: color,
                    ),
                  ),

                  const SizedBox(height: 1),

                  Text(
                    subtitle,
                    style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                  ),
                ],
              ),
            ),

            // Indicates that the item can be opened.
            Icon(
              Icons.arrow_forward_ios,
              size: 14,
              color: Colors.grey.shade400,
            ),
          ],
        ),
      ),
    );
  }
}
