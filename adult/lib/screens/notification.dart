import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../Controller/auth_controller.dart';
import 'package:adult/Controller/auth_controller.dart';

class NotificationPage extends StatefulWidget {
  const NotificationPage({super.key});
  @override
  State<NotificationPage> createState() => _NotificationPagestate();
}

class _NotificationPagestate extends State<NotificationPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 238, 238, 238),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _header(context), // ✅ added header
              _notificationcard(),
              const SizedBox(height: 10),
            ],
          ),
        ),
      ),
    );
  }
}

Widget _header(BuildContext context) {
  return Padding(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text(
          "Settings",
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
        ),
        TextButton.icon(
          onPressed: () async {
            final confirm = await showDialog<bool>(
              context: context,
              builder: (ctx) => AlertDialog(
                title: const Text("Logout"),
                content: const Text("Are you sure you want to logout?"),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(ctx, false),
                    child: const Text("Cancel"),
                  ),
                  TextButton(
                    onPressed: () => Navigator.pop(ctx, true),
                    child: const Text(
                      "Logout",
                      style: TextStyle(color: Colors.red),
                    ),
                  ),
                ],
              ),
            );

            if (confirm == true && context.mounted) {
              await context.read<AuthController>().logout();
              Navigator.pushNamedAndRemoveUntil(
                context,
                '/login', // ✅ change to your login route
                (route) => false,
              );
            }
          },
          icon: const Icon(Icons.logout, color: Colors.red),
          label: const Text("Logout", style: TextStyle(color: Colors.red)),
        ),
      ],
    ),
  );
}

// rest of your widgets stay exactly the same...
Widget _notificationcard() {
  return Container(
    margin: const EdgeInsets.all(16),
    padding: const EdgeInsets.symmetric(vertical: 8),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
    ),
    child: Column(
      children: [
        _buildTile(Icons.notifications_none, "Notifications"),
        _divider(),
        _buildTile(Icons.lock_outline, "Change Password"),
        _divider(),
        _buildTile(Icons.security, "Security"),
        _divider(),
        _buildTile(Icons.language, "Display and languages"),
        _divider(),
        _buildTile(Icons.help_outline, "Help"),
      ],
    ),
  );
}

Widget _buildTile(IconData icon, String title) {
  return ListTile(
    leading: Icon(icon, color: Colors.black54),
    title: Text(title, style: const TextStyle(fontSize: 16)),
    trailing: const Icon(Icons.arrow_forward_ios, size: 16),
    onTap: () {},
  );
}

Widget _divider() {
  return const Divider(height: 3, thickness: 0.5, indent: 16, endIndent: 16);
}
