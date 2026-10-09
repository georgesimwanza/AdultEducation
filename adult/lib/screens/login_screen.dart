import 'package:adult/screens/register_institution.dart';
import 'package:adult/screens/register_screen.dart';
import 'package:adult/screens/loading_screen.dart';
import 'package:adult/screens/auth_widget.dart';
import 'package:adult/screens/color.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:adult/Controller/auth_controller.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  bool _rememberMe = false;
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  @override
  void dispose() {
    passwordController.dispose();
    emailController.dispose();
    super.dispose();
  }

  Future<void> _login(AuthController controller) async {
    if (emailController.text.trim().isEmpty ||
        passwordController.text.trim().isEmpty) {
      showAuthSnack(
        ScaffoldMessenger.of(context),
        'Please fill in all fields',
        isError: true,
      );
      return;
    }

    final success = await controller.login(
      emailController.text.trim(),
      passwordController.text.trim(),
    );

    if (success && mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const LoadingScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = Provider.of<AuthController>(context);

    return AuthScaffold(
      title: 'Welcome back 👋',
      subtitle: 'Sign in to continue learning',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
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
          const SizedBox(height: 14),

          if (controller.errorMessage != null) ...[
            AuthErrorBanner(controller.errorMessage!),
            const SizedBox(height: 12),
          ],

          // Remember Me & Forgot Password
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              GestureDetector(
                onTap: () => setState(() => _rememberMe = !_rememberMe),
                child: Row(
                  children: [
                    SizedBox(
                      width: 24,
                      height: 24,
                      child: Checkbox(
                        value: _rememberMe,
                        activeColor: EduColors.primary,
                        side: const BorderSide(
                            color: EduColors.textSecondary, width: 1.4),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(6),
                        ),
                        onChanged: (val) =>
                            setState(() => _rememberMe = val ?? false),
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        visualDensity: VisualDensity.compact,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'Remember me',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: EduColors.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
              TextButton(
                onPressed: () {
                  // TODO: Add Forgot Password Route
                },
                style: TextButton.styleFrom(padding: EdgeInsets.zero),
                child: const Text(
                  'Forgot password?',
                  style: TextStyle(
                    color: EduColors.primary,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 22),

          AuthPrimaryButton(
            label: 'Login',
            loading: controller.isLoading,
            onPressed: () => _login(controller),
          ),
          const SizedBox(height: 18),

          // "or" divider
          Row(
            children: const [
              Expanded(child: Divider(color: EduColors.border)),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 12),
                child: Text(
                  'or',
                  style: TextStyle(
                    color: EduColors.textSecondary,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Expanded(child: Divider(color: EduColors.border)),
            ],
          ),
          const SizedBox(height: 18),

          AuthSecondaryButton(
            label: 'Register Institution',
            icon: Icons.apartment_rounded,
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const RegisterInstitutionScreen(),
                ),
              );
            },
          ),
          const SizedBox(height: 26),

          // Footer
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                "Don't have an account? ",
                style: TextStyle(
                  color: EduColors.textSecondary,
                  fontSize: 14,
                ),
              ),
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const RegisterScreen(),
                    ),
                  );
                },
                child: const Text(
                  'Sign up',
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