import 'package:flutter/material.dart';

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
            children: [_notificationcard(), const SizedBox(height: 10)],
          ),
        ),
      ),
    );
  }
}

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
    onTap: () {
      // handle navigation here
    },
  );
}

Widget _divider() {
  return const Divider(height: 3, thickness: 0.5, indent: 16, endIndent: 16);
}
