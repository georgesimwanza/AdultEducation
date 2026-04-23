import 'package:adult/Controller/auth_controller.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import './screens/register_screen.dart';
import './screens/dashboard.dart';
import 'package:adult/screens/login_screen.dart';
import './screens/subject.dart';
import './screens/coursepage.dart';

void main() {
  runApp(
    ChangeNotifierProvider(
      create: (_) => AuthController(),
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
      home: const LoginPage(),
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
          default:
            return null;
        }
      },
    );
  }
}
