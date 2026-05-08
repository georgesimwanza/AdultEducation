import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:adult/Controller/auth_controller.dart';
import 'package:adult/screens/login_screen.dart';
import 'package:adult/screens/navbar.dart'; // StudentNavBar
import 'package:adult/screens/admin/navbar.dart'; // AdminNavBar

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthController>(context);

    if (auth.isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (auth.token == null) {
      return const LoginPage();
    }

    if (auth.role == 'ADMIN') {
      return const AdminNavBar();
    }

    return const StudentNavBar();
  }
}
