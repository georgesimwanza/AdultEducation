import 'package:adult/service/institution_service.dart';
import 'package:adult/screens/auth_widget.dart';
import 'package:adult/screens/color.dart';
import 'package:flutter/material.dart';

/// Provides a form for registering a new institution.
///
/// The screen collects the institution's:
/// - Name
/// - Email address
/// - Location
/// - Password
///
/// Registration is handled through [InstitutionService].
class RegisterInstitutionScreen extends StatefulWidget {
  const RegisterInstitutionScreen({super.key});

  @override
  State<RegisterInstitutionScreen> createState() =>
      _RegisterInstitutionScreenState();
}

class _RegisterInstitutionScreenState extends State<RegisterInstitutionScreen> {
  // Controllers used to retrieve values entered into the form.
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
  TextEditingController();

  // Service responsible for communicating with the institution API.
  final InstitutionService _institutionService = InstitutionService();

  // This request goes through InstitutionService (not AuthController),
  // so the loading and error state live here.
  bool _isSubmitting = false;
  String? _error;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _locationController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _fail(String message) {
    setState(() => _error = message);
    showAuthSnack(ScaffoldMessenger.of(context), message, isError: true);
  }

  /// Validates the registration form and registers the institution.
  Future<void> _submit() async {
    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final location = _locationController.text.trim();
    final password = _passwordController.text.trim();
    final confirm = _confirmPasswordController.text.trim();

    setState(() => _error = null);

    // Make sure every required field has been completed.
    if (name.isEmpty ||
        email.isEmpty ||
        location.isEmpty ||
        password.isEmpty ||
        confirm.isEmpty) {
      _fail('Please fill in all fields');
      return;
    }

    if (!email.contains('@')) {
      _fail('Please enter a valid email address');
      return;
    }

    // Ensure that the password and confirmation password match.
    if (password != confirm) {
      _fail('Passwords do not match');
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      // Send the registration details to the backend.
      await _institutionService.registerInstitution(
        name: name,
        email: email,
        location: location,
        password: password,
      );

      if (!mounted) return;

      showAuthSnack(
        ScaffoldMessenger.of(context),
        'Institution registered successfully',
      );

      // Return to the previous screen after registration.
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      _fail(e.toString().replaceFirst('Exception: ', ''));
    }
  }

  @override
  Widget build(BuildContext context) {
    return AuthScaffold(
      title: 'Register institution',
      subtitle: 'Set up your school or college on PAMODZI',
      showBack: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AuthField(
            label: 'Institution name',
            hint: 'e.g. Copperbelt University',
            icon: Icons.business_rounded,
            controller: _nameController,
            keyboardType: TextInputType.text,
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: 18),
          AuthField(
            label: 'Email address',
            hint: 'admin@institution.ac.zm',
            icon: Icons.mail_outline_rounded,
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: 18),
          AuthField(
            label: 'Location',
            hint: 'e.g. Ndola, Zambia',
            icon: Icons.location_on_outlined,
            controller: _locationController,
            keyboardType: TextInputType.streetAddress,
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: 18),
          AuthField(
            label: 'Password',
            hint: 'Create a strong password',
            icon: Icons.lock_outline_rounded,
            controller: _passwordController,
            isPassword: true,
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: 18),
          AuthField(
            label: 'Confirm password',
            hint: 'Repeat your password',
            icon: Icons.lock_reset_rounded,
            controller: _confirmPasswordController,
            isPassword: true,
            textInputAction: TextInputAction.done,
          ),
          const SizedBox(height: 16),

          if (_error != null) ...[
            AuthErrorBanner(_error!),
            const SizedBox(height: 14),
          ],

          const SizedBox(height: 4),
          AuthPrimaryButton(
            label: 'Register Institution',
            loading: _isSubmitting,
            onPressed: _submit,
          ),
          const SizedBox(height: 24),

          // Footer providing a way back to the sign-in screen.
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'Already registered? ',
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
  }
}

// Kept (unused here) in case another screen imports TopWaveClipper from
// this file. Delete if nothing references it.
class TopWaveClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    path.moveTo(0, 50);

    final firstControlPoint = Offset(size.width * 0.35, 0);
    final firstEndPoint = Offset(size.width * 0.65, 45);
    final secondEndPoint = Offset(size.width, 50);

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