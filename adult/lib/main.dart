import 'package:adult/Controller/AuthWrapper.dart';
import 'package:adult/Controller/auth_controller.dart';
import 'package:adult/screens/login_screen.dart';
import 'package:adult/service/sync_service.dart'; // ← add this
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import './screens/coursepage.dart';
import './screens/dashboard.dart';
import './screens/schedule_screen.dart';
import './screens/subject.dart';
import 'Controller/schedule_controller.dart';

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
  if (auth.token != null) {
    await syncService.syncOnStartup();
  } else {
    // still init the db so offline reads work
    await syncService.initDb();
  }

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: auth),
        ChangeNotifierProvider(create: (_) => ScheduleController()),
        Provider.value(value: syncService), // ← expose syncService to the app
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
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
