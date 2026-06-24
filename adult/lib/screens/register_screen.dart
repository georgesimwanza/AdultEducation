import 'package:adult/Model/insititution.dart';
import 'package:adult/service/institution_service.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'programmes.dart';
import 'package:adult/Controller/auth_controller.dart';
import 'package:adult/Model/programme_model.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

// Fixed state class name pairing to match best practices
class _RegisterScreenState extends State<RegisterScreen> {
  ProgrammeModel? selectedCourse;
  Institution? selectedInstitution;
  List<Institution> _institution = [];
  final InstitutionService _institutionService = InstitutionService();

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
  void initState() {
    super.initState();
    _loadInstitutions();
  }

  Future<void> _loadInstitutions() async {
    final institutions = await _institutionService.getInstitutions();
    setState(() => _institution = institutions);
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthController>(
      builder: (context, controller, _) {
        return Scaffold(
          // Solid black matching top layer
          backgroundColor: Colors.black,
          resizeToAvoidBottomInset: true,
          body: Stack(
            children: [
              // Wave-Clipped Form Sheet Container
              Align(
                alignment: Alignment.bottomCenter,
                child: ClipPath(
                  clipper: TopWaveClipper(), // Replicated top wave design cut
                  child: Container(
                    height: MediaQuery.of(context).size.height * 0.82,
                    color: Colors.white,
                    padding: const EdgeInsets.only(
                      left: 28,
                      right: 28,
                      top: 65,
                      bottom: 24,
                    ),
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Sign Up Page Title Heading
                          const Text(
                            'Sign up',
                            style: TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                            ),
                          ),
                          const SizedBox(height: 24),

                          // Firstname Field Label & Underline Input
                          const Text(
                            'First Name',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: Colors.grey,
                            ),
                          ),
                          TextField(
                            controller: firstnameController,
                            keyboardType: TextInputType.text,
                            style: const TextStyle(color: Colors.black),
                            decoration: InputDecoration(
                              hintText: 'John',
                              hintStyle: const TextStyle(
                                color: Colors.grey,
                                fontSize: 14,
                              ),
                              prefixIcon: const Icon(
                                Icons.badge_outlined,
                                color: Colors.grey,
                                size: 20,
                              ),
                              prefixIconConstraints: const BoxConstraints(
                                minWidth: 30,
                                minHeight: 20,
                              ),
                              enabledBorder: UnderlineInputBorder(
                                borderSide: BorderSide(
                                  color: Colors.grey.shade300,
                                ),
                              ),
                              focusedBorder: const UnderlineInputBorder(
                                borderSide: BorderSide(
                                  color: Colors.black,
                                  width: 2,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),

                          // Lastname Field Label & Underline Input
                          const Text(
                            'Last Name',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: Colors.grey,
                            ),
                          ),
                          TextField(
                            controller: lastnameController,
                            keyboardType: TextInputType.text,
                            style: const TextStyle(color: Colors.black),
                            decoration: InputDecoration(
                              hintText: 'Doe',
                              hintStyle: const TextStyle(
                                color: Colors.grey,
                                fontSize: 14,
                              ),
                              prefixIcon: const Icon(
                                Icons.person_outline,
                                color: Colors.grey,
                                size: 20,
                              ),
                              prefixIconConstraints: const BoxConstraints(
                                minWidth: 30,
                                minHeight: 20,
                              ),
                              enabledBorder: UnderlineInputBorder(
                                borderSide: BorderSide(
                                  color: Colors.grey.shade300,
                                ),
                              ),
                              focusedBorder: const UnderlineInputBorder(
                                borderSide: BorderSide(
                                  color: Colors.black,
                                  width: 2,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),

                          // Email Field Label & Underline Input
                          const Text(
                            'Email',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: Colors.grey,
                            ),
                          ),
                          TextField(
                            controller: emailController,
                            keyboardType: TextInputType.emailAddress,
                            style: const TextStyle(color: Colors.black),
                            decoration: InputDecoration(
                              hintText: 'demo@email.com',
                              hintStyle: const TextStyle(
                                color: Colors.grey,
                                fontSize: 14,
                              ),
                              prefixIcon: const Icon(
                                Icons.mail_outline,
                                color: Colors.grey,
                                size: 20,
                              ),
                              prefixIconConstraints: const BoxConstraints(
                                minWidth: 30,
                                minHeight: 20,
                              ),
                              enabledBorder: UnderlineInputBorder(
                                borderSide: BorderSide(
                                  color: Colors.grey.shade300,
                                ),
                              ),
                              focusedBorder: const UnderlineInputBorder(
                                borderSide: BorderSide(
                                  color: Colors.black,
                                  width: 2,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),

                          // Password Field Label & Underline Input
                          const Text(
                            'Password',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: Colors.grey,
                            ),
                          ),
                          TextField(
                            controller: passwordController,
                            obscureText: true,
                            style: const TextStyle(color: Colors.black),
                            decoration: InputDecoration(
                              hintText: 'Enter your password',
                              hintStyle: const TextStyle(
                                color: Colors.grey,
                                fontSize: 14,
                              ),
                              prefixIcon: const Icon(
                                Icons.lock_outline,
                                color: Colors.grey,
                                size: 20,
                              ),
                              prefixIconConstraints: const BoxConstraints(
                                minWidth: 30,
                                minHeight: 20,
                              ),
                              enabledBorder: UnderlineInputBorder(
                                borderSide: BorderSide(
                                  color: Colors.grey.shade300,
                                ),
                              ),
                              focusedBorder: const UnderlineInputBorder(
                                borderSide: BorderSide(
                                  color: Colors.black,
                                  width: 2,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),

                          // Monochromatic Black-Border Course Picker Button
                          const Text(
                            'Programme',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: Colors.grey,
                            ),
                          ),
                          const SizedBox(height: 8),
                          SizedBox(
                            height: 52,
                            child: OutlinedButton(
                              onPressed: () async {
                                final navigator = Navigator.of(context);
                                final course = await navigator
                                    .push<ProgrammeModel>(
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            const ProgrammePage(),
                                      ),
                                    );

                                if (course != null) {
                                  setState(() => selectedCourse = course);
                                }
                              },
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(
                                  color: Colors.black,
                                  width: 1.5,
                                ),
                                foregroundColor: Colors.black,
                                alignment: Alignment.centerLeft,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    selectedCourse?.name ?? 'Choose Programme',
                                    style: const TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  const Icon(
                                    Icons.arrow_drop_down,
                                    color: Colors.black,
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),

                          const SizedBox(height: 24),
                          const Text(
                            'Institution',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: Colors.grey,
                            ),
                          ),
                          const SizedBox(height: 8),
                          DropdownButtonFormField<Institution>(
                            value: selectedInstitution,
                            items: _institution
                                .map(
                                  (inst) => DropdownMenuItem(
                                    value: inst,
                                    child: Text(inst.name),
                                  ),
                                )
                                .toList(),
                            onChanged: (val) =>
                                setState(() => selectedInstitution = val),
                            decoration: InputDecoration(
                              hintText: 'Select Institution',
                              hintStyle: const TextStyle(
                                color: Colors.grey,
                                fontSize: 14,
                              ),
                              prefixIcon: const Icon(
                                Icons.school_outlined,
                                color: Colors.grey,
                                size: 20,
                              ),
                              enabledBorder: UnderlineInputBorder(
                                borderSide: BorderSide(
                                  color: Colors.grey.shade300,
                                ),
                              ),
                              focusedBorder: const UnderlineInputBorder(
                                borderSide: BorderSide(
                                  color: Colors.black,
                                  width: 2,
                                ),
                              ),
                            ),
                          ),

                          // Dynamic Error Message Widget
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

                          // Solid Black Primary Register Action Button
                          SizedBox(
                            height: 52,
                            child: ElevatedButton(
                              onPressed: controller.isLoading
                                  ? null
                                  : () async {
                                      final navigator = Navigator.of(context);
                                      final messenger = ScaffoldMessenger.of(
                                        context,
                                      );

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

                                      if (selectedInstitution == null) {
                                        messenger.showSnackBar(
                                          const SnackBar(
                                            content: Text(
                                              'Please select an institution',
                                            ),
                                          ),
                                        );
                                        return;
                                      }

                                      final success = await controller.register(
                                        firstName: firstnameController.text
                                            .trim(),
                                        lastName: lastnameController.text
                                            .trim(),
                                        email: emailController.text.trim(),
                                        password: passwordController.text
                                            .trim(),
                                        programmeId: selectedCourse!.id,
                                        institutionId: selectedInstitution!.id,
                                      );

                                      if (success) {
                                        navigator.pushReplacementNamed(
                                          '/dashboard',
                                        );
                                      }
                                    },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.black,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                textStyle: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              child: controller.isLoading
                                  ? const SizedBox(
                                      height: 22,
                                      width: 22,
                                      child: CircularProgressIndicator(
                                        color: Colors.white,
                                        strokeWidth: 2.5,
                                      ),
                                    )
                                  : const Text('Register'),
                            ),
                          ),
                          const SizedBox(height: 24),

                          // Back to Sign In Link Footer
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Text(
                                "Already have an Account? ",
                                style: TextStyle(
                                  color: Colors.grey,
                                  fontSize: 14,
                                ),
                              ),
                              GestureDetector(
                                onTap: () {
                                  Navigator.pop(context);
                                },
                                child: const Text(
                                  'Sign in',
                                  style: TextStyle(
                                    color: Colors.black,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
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

// Shared Top Wave Clipper configuration matching login structure
class TopWaveClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    var path = Path();
    path.moveTo(0, 50);

    var firstControlPoint = Offset(size.width * 0.35, 0);
    var firstEndPoint = Offset(size.width * 0.65, 45);

    var secondControlPoint = Offset(size.width * 0.85, 75);
    var secondEndPoint = Offset(size.width, 50);

    path.cubicTo(
      firstControlPoint.dx,
      firstControlPoint.dy,
      firstEndPoint.dx,
      firstEndPoint.dy,
      secondEndPoint.dx,
      secondEndPoint.dy,
    );

    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}
