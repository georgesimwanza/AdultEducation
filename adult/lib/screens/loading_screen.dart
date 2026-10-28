import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:adult/Controller/AuthWrapper.dart';
import 'package:adult/Controller/auth_controller.dart';
import 'package:adult/service/sync_service.dart';

/// Shown right after a successful login, while local data syncs.
/// Displays live staged status text (driven by SyncService's onProgress
/// callback) instead of a bare spinner, then hands over to AuthWrapper,
/// which shows the student or admin navbar for the signed-in role.
class LoadingScreen extends StatefulWidget {
  const LoadingScreen({super.key});

  @override
  State<LoadingScreen> createState() => _LoadingScreenState();
}

class _LoadingScreenState extends State<LoadingScreen> {
  String _status = 'Signing you in...';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _runSync());
  }

  Future<void> _runSync() async {
    final authController = context.read<AuthController>();
    final syncService = SyncService(authController: authController);

    try {
      await syncService.syncOnStartup(
        onProgress: (stage) {
          if (mounted) setState(() => _status = stage);
        },
      );
    } catch (e) {
      // Sync failures shouldn't block the user from reaching the app —
      // SyncService already swallows per-table errors internally, this
      // just guards against something unexpected at the top level.
      debugPrint('Sync error during loading screen: $e');
    }

    if (!mounted) return;
    // AuthWrapper picks StudentNavBar / AdminNavBar by role; the bare
    // '/dashboard' route has no navbar and ignores the role.
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const AuthWrapper()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(
              width: 36,
              height: 36,
              child: CircularProgressIndicator(
                color: Colors.black,
                strokeWidth: 3,
              ),
            ),
            const SizedBox(height: 24),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 250),
              child: Text(
                _status,
                key: ValueKey(_status),
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
