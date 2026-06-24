import 'dart:developer';

import 'package:adult/service/institution_service.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:adult/Controller/auth_controller.dart';

class RegisterInstitutionScreen extends StatefulWidget {
  const RegisterInstitutionScreen({super.key});

  @override
  State<RegisterInstitutionScreen> createState() =>
      _RegisterInstitutionScreenState();
}

class _RegisterInstitutionScreenState extends State<RegisterInstitutionScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();
  final InstitutionService _institutionService = InstitutionService();
  bool _obscurePassword = true;
  bool _obscureConfirm = true;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _locationController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _submit() async {
    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final location = _locationController.text.trim();
    final password = _passwordController.text.trim();
    final confirm = _confirmPasswordController.text.trim();

    if (name.isEmpty ||
        email.isEmpty ||
        location.isEmpty ||
        password.isEmpty ||
        confirm.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in all fields')),
      );
      return;
    }

    if (password != confirm) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Passwords do not match')));
      return;
    }

    try {
      await _institutionService.registerInstitution(
        name: name,
        email: email,
        location: location,
        password: password,
      );
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Institution registered successfully')),
      );
      Navigator.pop(context);
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = Provider.of<AuthController>(context);

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // ── Back button floating above the wave ──
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.only(left: 8, top: 4),
              child: IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(
                  Icons.arrow_back_ios_new,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ),
          ),

          // ── Header text on the black section ──
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.only(left: 28, top: 52),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: const [
                  Text(
                    'Register',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: -0.5,
                    ),
                  ),
                  Text(
                    'Institution',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.white70,
                      letterSpacing: -0.5,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── Wave-clipped white form sheet ──
          Align(
            alignment: Alignment.bottomCenter,
            child: ClipPath(
              clipper: TopWaveClipper(),
              child: Container(
                height: MediaQuery.of(context).size.height * 0.80,
                color: Colors.white,
                padding: const EdgeInsets.only(
                  left: 28,
                  right: 28,
                  top: 64,
                  bottom: 24,
                ),
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Institution Name
                      _FieldLabel('Institution Name'),
                      _buildField(
                        controller: _nameController,
                        hint: 'e.g. Copperbelt University',
                        icon: Icons.business_outlined,
                      ),
                      const SizedBox(height: 20),

                      // Email
                      _FieldLabel('Email Address'),
                      _buildField(
                        controller: _emailController,
                        hint: 'admin@institution.ac.zm',
                        icon: Icons.mail_outline,
                        keyboardType: TextInputType.emailAddress,
                      ),
                      const SizedBox(height: 20),

                      // Location
                      _FieldLabel('Location'),
                      _buildField(
                        controller: _locationController,
                        hint: 'e.g. Ndola, Zambia',
                        icon: Icons.location_on_outlined,
                      ),
                      const SizedBox(height: 20),

                      // Password
                      _FieldLabel('Password'),
                      _buildField(
                        controller: _passwordController,
                        hint: 'Create a strong password',
                        icon: Icons.lock_outline,
                        obscure: _obscurePassword,
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword
                                ? Icons.visibility_off_outlined
                                : Icons.visibility_outlined,
                            color: Colors.grey,
                            size: 20,
                          ),
                          onPressed: () => setState(
                            () => _obscurePassword = !_obscurePassword,
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Confirm Password
                      _FieldLabel('Confirm Password'),
                      _buildField(
                        controller: _confirmPasswordController,
                        hint: 'Repeat your password',
                        icon: Icons.lock_outline,
                        obscure: _obscureConfirm,
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscureConfirm
                                ? Icons.visibility_off_outlined
                                : Icons.visibility_outlined,
                            color: Colors.grey,
                            size: 20,
                          ),
                          onPressed: () => setState(
                            () => _obscureConfirm = !_obscureConfirm,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Error message
                      if (controller.errorMessage != null)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Text(
                            controller.errorMessage!,
                            style: const TextStyle(
                              color: Colors.red,
                              fontSize: 13,
                            ),
                          ),
                        ),

                      const SizedBox(height: 20),

                      // Primary Register Button
                      SizedBox(
                        height: 52,
                        child: ElevatedButton(
                          onPressed: controller.isLoading
                              ? null
                              : () => _submit(),
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
                              : const Text('Register Institution'),
                        ),
                      ),
                      const SizedBox(height: 28),

                      // Footer
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text(
                            'Already registered? ',
                            style: TextStyle(color: Colors.grey, fontSize: 14),
                          ),
                          GestureDetector(
                            onTap: () => Navigator.pop(context),
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
  }

  Widget _buildField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    bool obscure = false,
    Widget? suffixIcon,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscure,
      style: const TextStyle(color: Colors.black),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.grey, fontSize: 14),
        prefixIcon: Icon(icon, color: Colors.grey, size: 20),
        prefixIconConstraints: const BoxConstraints(
          minWidth: 30,
          minHeight: 20,
        ),
        suffixIcon: suffixIcon,
        enabledBorder: UnderlineInputBorder(
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: const UnderlineInputBorder(
          borderSide: BorderSide(color: Colors.black, width: 2),
        ),
      ),
    );
  }
}

// Tiny label widget kept DRY
class _FieldLabel extends StatelessWidget {
  final String text;
  const _FieldLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: Colors.grey,
        ),
      ),
    );
  }
}

// Same wave clipper from LoginPage — keep in a shared file (e.g. clippers.dart)
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
