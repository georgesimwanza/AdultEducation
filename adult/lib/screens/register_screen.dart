import 'package:adult/Model/insititution.dart';
import 'package:adult/service/institution_service.dart';
import 'package:adult/screens/auth_widget.dart';
import 'package:adult/screens/color.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'programmes.dart';
import 'package:adult/Controller/auth_controller.dart';
import 'package:adult/Model/programme_model.dart';
import 'package:adult/screens/loading_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  ProgrammeModel? selectedCourse;
  Institution? selectedInstitution;
  List<Institution> _institution = [];
  bool _loadingInstitutions = true;
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
    try {
      final institutions = await _institutionService.getInstitutions();
      if (!mounted) return;
      setState(() {
        _institution = institutions;
        _loadingInstitutions = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loadingInstitutions = false);
      showAuthSnack(
        ScaffoldMessenger.of(context),
        'Could not load institutions. Check your connection.',
        isError: true,
      );
    }
  }

  Future<void> _pickProgramme() async {
    final navigator = Navigator.of(context);
    final course = await navigator.push<ProgrammeModel>(
      MaterialPageRoute(builder: (context) => const ProgrammePage()),
    );

    if (course != null && mounted) {
      setState(() => selectedCourse = course);
    }
  }

  Future<void> _register(AuthController controller) async {
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);

    if (firstnameController.text.trim().isEmpty ||
        lastnameController.text.trim().isEmpty ||
        emailController.text.trim().isEmpty ||
        passwordController.text.trim().isEmpty) {
      showAuthSnack(messenger, 'Please fill in all fields', isError: true);
      return;
    }

    if (selectedCourse == null) {
      showAuthSnack(messenger, 'Please select a course', isError: true);
      return;
    }

    if (selectedInstitution == null) {
      showAuthSnack(messenger, 'Please select an institution', isError: true);
      return;
    }

    final success = await controller.register(
      firstName: firstnameController.text.trim(),
      lastName: lastnameController.text.trim(),
      email: emailController.text.trim(),
      password: passwordController.text.trim(),
      programmeId: selectedCourse!.id,
      institutionId: selectedInstitution!.id,
    );

    if (success && navigator.mounted) {
      showAuthSnack(messenger, 'Registration successful');
      // Same post-auth flow as LoginPage: LoadingScreen runs the initial
      // sync then redirects to '/dashboard', which resolves to the correct
      // student/admin shell based on the stored role.
      navigator.pushReplacement(
        MaterialPageRoute(builder: (_) => const LoadingScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthController>(
      builder: (context, controller, _) {
        return AuthScaffold(
          title: 'Create account',
          subtitle: 'Join and learn at your own pace',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // First + last name side by side
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: AuthField(
                      label: 'First name',
                      hint: 'John',
                      icon: Icons.badge_outlined,
                      controller: firstnameController,
                      keyboardType: TextInputType.name,
                      textInputAction: TextInputAction.next,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: AuthField(
                      label: 'Last name',
                      hint: 'Doe',
                      icon: Icons.person_outline_rounded,
                      controller: lastnameController,
                      keyboardType: TextInputType.name,
                      textInputAction: TextInputAction.next,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              AuthField(
                label: 'Email',
                hint: 'demo@email.com',
                icon: Icons.mail_outline_rounded,
                controller: emailController,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 18),
              AuthField(
                label: 'Password',
                hint: 'Enter your password',
                icon: Icons.lock_outline_rounded,
                controller: passwordController,
                isPassword: true,
                textInputAction: TextInputAction.done,
              ),
              const SizedBox(height: 18),

              AuthPickerField(
                label: 'Programme',
                placeholder: 'Choose programme',
                value: selectedCourse?.name,
                icon: Icons.menu_book_rounded,
                onTap: _pickProgramme,
              ),
              const SizedBox(height: 18),

              // Institution dropdown
              const AuthLabel('Institution'),
              DropdownButtonFormField<Institution>(
                value: selectedInstitution,
                isExpanded: true,
                icon: const Icon(Icons.keyboard_arrow_down_rounded,
                    color: EduColors.textSecondary),
                dropdownColor: EduColors.surface,
                borderRadius: BorderRadius.circular(16),
                style: const TextStyle(
                  color: EduColors.textPrimary,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
                items: _institution
                    .map(
                      (inst) => DropdownMenuItem(
                    value: inst,
                    child: Text(inst.name, overflow: TextOverflow.ellipsis),
                  ),
                )
                    .toList(),
                onChanged: (val) => setState(() => selectedInstitution = val),
                decoration: authInputDecoration(
                  hint: _loadingInstitutions
                      ? 'Loading institutions…'
                      : 'Select institution',
                  icon: Icons.school_outlined,
                ),
              ),
              const SizedBox(height: 18),

              if (controller.errorMessage != null) ...[
                AuthErrorBanner(controller.errorMessage!),
                const SizedBox(height: 14),
              ],

              AuthPrimaryButton(
                label: 'Register',
                loading: controller.isLoading,
                onPressed: () => _register(controller),
              ),
              const SizedBox(height: 22),

              // Back to Sign In
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'Already have an account? ',
                    style: TextStyle(
                      color: EduColors.textSecondary,
                      fontSize: 14,
                    ),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: const Text(
                      'Sign in',
                      style: TextStyle(
                        color: EduColors.primary,
                        fontWeight: FontWeight.w800,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

// Kept (unused here) in case another screen, e.g. register_institution.dart,
// imports TopWaveClipper from this file. Delete if nothing references it.
class TopWaveClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    var path = Path();
    path.moveTo(0, 50);

    var firstControlPoint = Offset(size.width * 0.35, 0);
    var firstEndPoint = Offset(size.width * 0.65, 45);

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