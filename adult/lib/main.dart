import 'package:adult/Controller/auth_controller.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import './screens/register_screen.dart';
import './screens/dashboard.dart';
import 'package:adult/screens/login_screen.dart';
import './screens/subject.dart';
import './screens/coursepage.dart';
import './screens/schedule_screen.dart';
import 'Controller/schedule_controller.dart';
import './screens/admin/content_screen.dart';
import './screens/navbar.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthController()),
        ChangeNotifierProvider(create: (_) => ScheduleController()),
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
      home: LoginPage(),
      onGenerateRoute: (settings) {
        switch (settings.name) {
          case '/dashboard':
            return MaterialPageRoute(builder: (_) => const Dashboard());
          case '/login':
            return MaterialPageRoute(builder: (_) => const LoginPage());
          case '/subject':
            return MaterialPageRoute(builder: (_) => const SubjectPage());
          case '/coursepage':
            return MaterialPageRoute(builder: (_) => const CoursePage());
          case '/schedule':
            return MaterialPageRoute(builder: (_) => const ScheduleScreen());
          default:
            return null;
        }
      },
    );
  }
}
