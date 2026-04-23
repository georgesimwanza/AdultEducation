import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'programmes.dart';
import 'package:adult/Controller/auth_controller.dart';
import 'package:adult/Model/programme_model.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _LoginPageState();
}

class _LoginPageState extends State<RegisterScreen> {
  ProgrammeModel? selectedCourse;

  final TextEditingController firstnameController = TextEditingController();
  final TextEditingController lastnameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  @override
  void dispose() {
    firstnameController.dispose();
    lastnameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthController>(
      builder: (context, controller, _) {
        return Scaffold(
          resizeToAvoidBottomInset: true,
          body: Stack(
            children: [
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                height: MediaQuery.of(context).size.height * 0.25,
                child: Image.asset('assets/cover.png', fit: BoxFit.cover),
              ),

              Align(
                alignment: Alignment.bottomCenter,
                child: Container(
                  height: MediaQuery.of(context).size.height * 0.75,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(32),
                      topRight: Radius.circular(32),
                    ),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 28,
                    vertical: 32,
                  ),
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Firstname
                        TextField(
                          controller: firstnameController,
                          keyboardType: TextInputType.text,
                          decoration: InputDecoration(
                            hintText: 'Enter Firstname',
                            prefixIcon: const Icon(
                              Icons.badge_outlined,
                              color: Colors.grey,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),

                        const SizedBox(height: 16),

                        // Lastname
                        TextField(
                          controller: lastnameController,
                          decoration: InputDecoration(
                            hintText: 'Enter Lastname',
                            prefixIcon: const Icon(
                              Icons.person,
                              color: Colors.grey,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),

                        const SizedBox(height: 16),

                        // Email
                        TextField(
                          controller: emailController,
                          keyboardType: TextInputType.emailAddress,
                          decoration: InputDecoration(
                            hintText: 'Enter Email',
                            prefixIcon: const Icon(
                              Icons.email_outlined,
                              color: Colors.grey,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),

                        const SizedBox(height: 16),

                        // Password
                        TextField(
                          controller: passwordController,
                          obscureText: true,
                          decoration: InputDecoration(
                            hintText: 'Enter Password',
                            prefixIcon: const Icon(
                              Icons.lock_outline,
                              color: Colors.grey,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),

                        const SizedBox(height: 16),

                        // Course picker
                        SizedBox(
                          height: 50,
                          child: OutlinedButton(
                            onPressed: () async {
                              final navigator = Navigator.of(
                                context,
                              ); // capture before await

                              final course = await navigator
                                  .push<ProgrammeModel>(
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          const ProgrammePage(),
                                    ),
                                  );

                              print(
                                'Selected course: ${course?.id} - ${course?.name}',
                              );

                              if (course != null) {
                                setState(() => selectedCourse = course);
                              }
                            },
                            style: OutlinedButton.styleFrom(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: Text(
                              selectedCourse?.name ?? 'Choose Programme',
                              style: const TextStyle(fontSize: 16),
                            ),
                          ),
                        ),

                        const SizedBox(height: 16),

                        // Show error message if any
                        if (controller.errorMessage != null)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: Text(
                              controller.errorMessage!,
                              style: const TextStyle(
                                color: Colors.red,
                                fontSize: 13,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),

                        // Register button
                        SizedBox(
                          height: 50,
                          child: ElevatedButton(
                            onPressed: controller.isLoading
                                ? null
                                : () async {
                                    final navigator = Navigator.of(
                                      context,
                                    ); // capture before await
                                    final messenger = ScaffoldMessenger.of(
                                      context,
                                    ); // capture before await

                                    if (firstnameController.text
                                            .trim()
                                            .isEmpty ||
                                        lastnameController.text
                                            .trim()
                                            .isEmpty ||
                                        emailController.text.trim().isEmpty ||
                                        passwordController.text
                                            .trim()
                                            .isEmpty) {
                                      messenger.showSnackBar(
                                        const SnackBar(
                                          content: Text(
                                            'Please fill in all fields',
                                          ),
                                        ),
                                      );
                                      return;
                                    }

                                    if (selectedCourse == null) {
                                      messenger.showSnackBar(
                                        const SnackBar(
                                          content: Text(
                                            'Please select a course',
                                          ),
                                        ),
                                      );
                                      return;
                                    }

                                    final success = await controller.register(
                                      firstName: firstnameController.text
                                          .trim(),
                                      lastName: lastnameController.text.trim(),
                                      email: emailController.text.trim(),
                                      password: passwordController.text.trim(),
                                      programmeId: selectedCourse!.id,
                                    );

                                    if (success) {
                                      navigator.pushReplacementNamed(
                                        '/dashboard',
                                      );
                                    }
                                  },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF1B2D5B),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: controller.isLoading
                                ? const CircularProgressIndicator(
                                    color: Colors.white,
                                  )
                                : const Text(
                                    'Register',
                                    style: TextStyle(fontSize: 16),
                                  ),
                          ),
                        ),

                        const SizedBox(height: 20),

                        Center(
                          child: Image.asset('assets/logo.png', height: 80),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
