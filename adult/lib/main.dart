import 'package:adult/Controller/AuthWrapper.dart';
import 'package:adult/Controller/auth_controller.dart';
import 'package:adult/core/connection_status_bar.dart';
import 'package:adult/core/responsive.dart';
import 'package:adult/screens/login_screen.dart';
import 'package:adult/service/sync_service.dart'; // ← add this
import 'package:adult/service/schedule_service.dart'; // ← add this
import 'package:adult/service/accessibility_settings.dart';
import 'package:adult/service/connectivity_service.dart';
import 'package:adult/service/offline_cache.dart';
import 'package:adult/service/notifications/notification_service.dart';
import 'package:adult/service/quiz_submission_service.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import './screens/coursepage.dart';
import './screens/dashboard.dart';
import './screens/schedule_screen.dart';
import './screens/subject.dart';
import 'Controller/schedule_controller.dart';

/// Lets code outside the widget tree (e.g. an expired login) close screens.
final navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(
    url: 'https://vuleceqwhdmzdiugsety.supabase.co',
    publishableKey: 'sb_publishable_lm84SUJHemNg2ovdvON27Q_r1_2-yGF',
  );
  final auth = AuthController();
  await auth.init();
  // ← sync on startup
  final syncService = SyncService(authController: auth);

  // Watches the connection; when it comes back, upload what was saved
  // offline, then refresh the local copy of the server's data.
  final connectivity = ConnectivityService(
    onReconnect: (report) async {
      final db = syncService.db;
      if (auth.token == null || db == null) return;
      if (auth.tokenExpired) {
        // Changes made offline stay saved and go up after signing in.
        report('Your session has expired. Please sign in again.');
        navigatorKey.currentState?.popUntil((route) => route.isFirst);
        await auth.expireSession();
        return;
      }
      report('Sending your schedule changes...');
      await ScheduleService(db: db).syncPendingChanges();
      report('Sending your quiz answers...');
      await QuizSubmissionService(db: db).syncPendingSubmissions();
      await syncService.syncOnStartup(onProgress: report);
    },
  );
  // While offline, reads come from the saved copy right away and changes
  // are kept on the device (see OfflineCache).
  OfflineCache.isOffline = () => !connectivity.isOnline;
  // The server stopped accepting the login (it lasts 24 hours): back to
  // the login screen, closing whatever was open on top.
  OfflineCache.onUnauthorized = () {
    if (auth.token == null) return;
    navigatorKey.currentState?.popUntil((route) => route.isFirst);
    auth.expireSession();
  };
  await connectivity.start();

  // Expired while the app was closed. Offline it stays signed in so the
  // saved data can still be read; the server will ask once it's back.
  if (auth.token != null && auth.tokenExpired && connectivity.isOnline) {
    await auth.expireSession();
  }

  if (auth.token != null && connectivity.isOnline) {
    await syncService.syncOnStartup();
  } else {
    // Offline or signed out: open the local db so saved data still shows.
    await syncService.initDb();
  }

  // ScheduleService needs the same local db so schedules can be
  // cached/read offline like everything else.
  //also record quizes
  final scheduleService = ScheduleService(db: syncService.db!);
  final scheduleController = ScheduleController(service: scheduleService);

  // Text size / data saver, chosen by the learner in My Profile
  final accessibility = AccessibilitySettings();
  await accessibility.load();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: auth),
        ChangeNotifierProvider(
          create: (_) => scheduleController,
        ),
        Provider.value(value: syncService), // ← expose syncService to the app
        ChangeNotifierProvider.value(value: accessibility),
        ChangeNotifierProvider.value(value: connectivity),
      ],
      child: const MyApp(),
    ),
  );

  // Notifications: permission, the background check for new content, and
  // reminders for upcoming study sessions (from the local copy if offline).
  // After runApp so the permission prompt and slow networks don't delay it.
  await NotificationService.init();
  if (auth.token != null) {
    await NotificationService.startBackgroundSync();
    final email = auth.email;
    if (email != null) await scheduleController.loadEntries(email);
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PAMODZI',
      navigatorKey: navigatorKey,
      debugShowCheckedModeBanner: false,
      scrollBehavior: const AppScrollBehavior(),
      // Learner's chosen text size, plus the online / offline indicator
      // above every screen.
      builder: (context, child) {
        final scale = context.watch<AccessibilitySettings>().textScale;
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(textScaler: TextScaler.linear(scale)),
          child: ConnectionStatusBar(child: child ?? const SizedBox.shrink()),
        );
      },
      home: const AuthWrapper(),
      onGenerateRoute: (settings) {
        switch (settings.name) {
          case '/dashboard':
            return MaterialPageRoute(builder: (_) => const Dashboard());
          case '/login':
            return MaterialPageRoute(builder: (_) => const LoginPage());
          case '/subject':
            return MaterialPageRoute(builder: (_) => const SubjectPage());
          case '/coursepage':
            {
              final subjectId = settings.arguments as int;
              return MaterialPageRoute(
                builder: (_) => CoursePage(subjectId: subjectId),
              );
            }
          case '/schedule':
            return MaterialPageRoute(builder: (_) => const ScheduleScreen());
          default:
            return MaterialPageRoute(builder: (_) => const LoginPage());
        }
      },
    );
  }
}
