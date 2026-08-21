import 'dart:developer';

import 'package:adult/service/institution_service.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:adult/Controller/auth_controller.dart';

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

  // Controls whether the password is hidden or visible.
  bool _obscurePassword = true;

  // Controls whether the confirmation password is hidden or visible.
  bool _obscureConfirm = true;

  @override
  void dispose() {
    // Dispose controllers when the screen is removed from memory.
    _nameController.dispose();
    _emailController.dispose();
    _locationController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();

    super.dispose();
  }

  /// Validates the registration form and registers the institution.
  ///
  /// Displays an error message when required fields are missing
  /// or the passwords do not match.
  Future<void> _submit() async {
    // Retrieve and clean all values entered by the user.
    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final location = _locationController.text.trim();
    final password = _passwordController.text.trim();
    final confirm = _confirmPasswordController.text.trim();

    // Make sure every required field has been completed.
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

    // Ensure that the password and confirmation password match.
    if (password != confirm) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Passwords do not match')));

      return;
    }

    try {
      // Send the registration details to the backend.
      await _institutionService.registerInstitution(
        name: name,
        email: email,
        location: location,
        password: password,
      );

      // Ensure the widget is still part of the widget tree
      // before interacting with the context.
      if (!context.mounted) return;

      // Inform the user that registration was successful.
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Institution registered successfully')),
      );

      // Return to the previous screen after registration.
      Navigator.pop(context);
    } catch (e) {
      // Make sure the widget still exists before displaying
      // an error message.
      if (!context.mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  @override
  Widget build(BuildContext context) {
    // Access authentication state so that the UI can respond
    // to loading and error states.
    final controller = Provider.of<AuthController>(context);

    return Scaffold(
      backgroundColor: Colors.black,

      // Stack allows the header and form to overlap visually.
      body: Stack(
        children: [
          // Back button positioned over the black header area.
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

          // Registration heading displayed on the black background.
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

          // White form area clipped with a curved wave at the top.
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
                      // Institution name field.
                      _FieldLabel('Institution Name'),

                      _buildField(
                        controller: _nameController,
                        hint: 'e.g. Copperbelt University',
                        icon: Icons.business_outlined,
                      ),

                      const SizedBox(height: 20),

                      // Institution email field.
                      _FieldLabel('Email Address'),

                      _buildField(
                        controller: _emailController,
                        hint: 'admin@institution.ac.zm',
                        icon: Icons.mail_outline,
                        keyboardType: TextInputType.emailAddress,
                      ),

                      const SizedBox(height: 20),

                      // Institution location field.
                      _FieldLabel('Location'),

                      _buildField(
                        controller: _locationController,
                        hint: 'e.g. Ndola, Zambia',
                        icon: Icons.location_on_outlined,
                      ),

                      const SizedBox(height: 20),

                      // Password field.
                      _FieldLabel('Password'),

                      _buildField(
                        controller: _passwordController,
                        hint: 'Create a strong password',
                        icon: Icons.lock_outline,
                        obscure: _obscurePassword,

                        // Allows the user to show or hide the password.
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword
                                ? Icons.visibility_off_outlined
                                : Icons.visibility_outlined,
                            color: Colors.grey,
                            size: 20,
                          ),
                          onPressed: () {
                            setState(() {
                              _obscurePassword = !_obscurePassword;
                            });
                          },
                        ),
                      ),

                      const SizedBox(height: 20),

                      // Confirm password field.
                      _FieldLabel('Confirm Password'),

                      _buildField(
                        controller: _confirmPasswordController,
                        hint: 'Repeat your password',
                        icon: Icons.lock_outline,
                        obscure: _obscureConfirm,

                        // Allows the user to show or hide the
                        // confirmation password.
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscureConfirm
                                ? Icons.visibility_off_outlined
                                : Icons.visibility_outlined,
                            color: Colors.grey,
                            size: 20,
                          ),
                          onPressed: () {
                            setState(() {
                              _obscureConfirm = !_obscureConfirm;
                            });
                          },
                        ),
                      ),

                      const SizedBox(height: 12),

                      // Display an authentication error when available.
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

                      // Main registration button.
                      SizedBox(
                        height: 52,
                        child: ElevatedButton(
                          // Disable the button while registration
                          // is already being processed.
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

                          // Show a loading indicator while registration
                          // is being processed.
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

                      // Footer providing a way back to the sign-in screen.
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

  /// Builds a reusable text input field.
  ///
  /// [controller] manages the entered text.
  /// [hint] provides an example of the expected input.
  /// [icon] identifies the type of information being entered.
  /// [keyboardType] controls the keyboard displayed on the device.
  /// [obscure] hides sensitive information such as passwords.
  /// [suffixIcon] allows additional controls such as visibility toggles.
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

        // Icon displayed before the input text.
        prefixIcon: Icon(icon, color: Colors.grey, size: 20),

        prefixIconConstraints: const BoxConstraints(
          minWidth: 30,
          minHeight: 20,
        ),

        // Optional action displayed at the end of the field.
        suffixIcon: suffixIcon,

        // Border displayed when the field is not focused.
        enabledBorder: UnderlineInputBorder(
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),

        // Border displayed while the field is focused.
        focusedBorder: const UnderlineInputBorder(
          borderSide: BorderSide(color: Colors.black, width: 2),
        ),
      ),
    );
  }
}

/// Small reusable label displayed above form fields.
///
/// Keeping this as a separate widget avoids duplicating
/// the same label styling throughout the registration form.
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

/// Creates the curved wave shape at the top of the
/// registration form.
///
/// This clipper is used by [ClipPath] to give the white
/// form section a curved upper edge.
class TopWaveClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();

    // Start slightly below the top-left corner.
    path.moveTo(0, 50);

    // Define the control and end points used to create
    // the curved wave.
    final firstControlPoint = Offset(size.width * 0.35, 0);

    final firstEndPoint = Offset(size.width * 0.65, 45);

    final secondEndPoint = Offset(size.width, 50);

    // Create the curved top edge using a cubic Bezier curve.
    path.cubicTo(
      firstControlPoint.dx,
      firstControlPoint.dy,
      firstEndPoint.dx,
      firstEndPoint.dy,
      secondEndPoint.dx,
      secondEndPoint.dy,
    );

    // Extend the shape down to the bottom-right corner.
    path.lineTo(size.width, size.height);

    // Extend across the bottom to the bottom-left corner.
    path.lineTo(0, size.height);

    // Close the path.
    path.close();

    return path;
  }

  /// The wave shape never changes after creation,
  /// so the clipper does not need to be recalculated.
  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) {
    return false;
  }
}
