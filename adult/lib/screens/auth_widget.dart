import 'package:flutter/material.dart';
import 'package:adult/screens/color.dart';

/// Shared building blocks for the Login and Register screens.
///
/// Save as: lib/widgets/auth_widgets.dart

/// Filled, rounded input decoration used by every auth field.
InputDecoration authInputDecoration({
  required String hint,
  required IconData icon,
  Widget? suffix,
}) {
  return InputDecoration(
    hintText: hint,
    hintStyle: const TextStyle(color: EduColors.textSecondary, fontSize: 14),
    prefixIcon: Icon(icon, color: EduColors.textSecondary, size: 20),
    suffixIcon: suffix,
    filled: true,
    fillColor: EduColors.background,
    contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: const BorderSide(color: EduColors.border),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: const BorderSide(color: EduColors.primary, width: 1.6),
    ),
  );
}

/// Gradient header + white rounded sheet that scrolls its [child].
class AuthScaffold extends StatelessWidget {
  final String title;
  final String subtitle;
  final Widget child;

  /// Shows a circular back button in the header (for pushed screens).
  final bool showBack;

  const AuthScaffold({
    super.key,
    required this.title,
    required this.subtitle,
    required this.child,
    this.showBack = false,
  });

  @override
  Widget build(BuildContext context) {
    // Collapse the big title while the keyboard is open so the form
    // keeps enough room on small screens.
    final keyboardOpen = MediaQuery.of(context).viewInsets.bottom > 0;

    return Scaffold(
      backgroundColor: EduColors.primary,
      resizeToAvoidBottomInset: true,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [EduColors.primary, EduColors.primaryDark],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Stack(
          children: [
            // Decorative circles
            Positioned(
              top: -60,
              right: -50,
              child: _circle(190, const Color(0x14FFFFFF)),
            ),
            Positioned(
              top: 70,
              left: -70,
              child: _circle(150, const Color(0x0DFFFFFF)),
            ),
            SafeArea(
              bottom: false,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 16, 24, 22),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            if (showBack) ...[
                              GestureDetector(
                                onTap: () => Navigator.maybePop(context),
                                child: Container(
                                  width: 42,
                                  height: 42,
                                  decoration: const BoxDecoration(
                                    color: EduColors.onPrimaryFaint,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.arrow_back_rounded,
                                    color: EduColors.onPrimary,
                                    size: 20,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                            ],
                            Container(
                              width: 42,
                              height: 42,
                              decoration: BoxDecoration(
                                color: EduColors.onPrimaryFaint,
                                borderRadius: BorderRadius.circular(13),
                              ),
                              child: const Icon(Icons.school_rounded,
                                  color: EduColors.onPrimary, size: 22),
                            ),
                            const SizedBox(width: 12),
                            const Text(
                              'PAMODZI',
                              style: TextStyle(
                                color: EduColors.onPrimary,
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 1.6,
                              ),
                            ),
                          ],
                        ),
                        AnimatedSize(
                          duration: const Duration(milliseconds: 200),
                          curve: Curves.easeOut,
                          alignment: Alignment.topLeft,
                          child: keyboardOpen
                              ? const SizedBox(width: double.infinity)
                              : Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 22),
                              Text(
                                title,
                                style: const TextStyle(
                                  color: EduColors.onPrimary,
                                  fontSize: 30,
                                  fontWeight: FontWeight.w800,
                                  height: 1.15,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                subtitle,
                                style: const TextStyle(
                                  color: EduColors.onPrimaryMuted,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Container(
                      width: double.infinity,
                      decoration: const BoxDecoration(
                        color: EduColors.surface,
                        borderRadius:
                        BorderRadius.vertical(top: Radius.circular(32)),
                      ),
                      child: ClipRRect(
                        borderRadius:
                        const BorderRadius.vertical(top: Radius.circular(32)),
                        child: SingleChildScrollView(
                          keyboardDismissBehavior:
                          ScrollViewKeyboardDismissBehavior.onDrag,
                          padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
                          child: child,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _circle(double size, Color color) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(color: color, shape: BoxShape.circle),
  );
}

/// Small label above a field.
class AuthLabel extends StatelessWidget {
  final String text;
  const AuthLabel(this.text, {super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w700,
          color: EduColors.textPrimary,
        ),
      ),
    );
  }
}

/// Labelled text field. Password fields get a working show/hide toggle.
class AuthField extends StatefulWidget {
  final String label;
  final String hint;
  final IconData icon;
  final TextEditingController controller;
  final TextInputType? keyboardType;
  final bool isPassword;
  final TextInputAction? textInputAction;

  const AuthField({
    super.key,
    required this.label,
    required this.hint,
    required this.icon,
    required this.controller,
    this.keyboardType,
    this.isPassword = false,
    this.textInputAction,
  });

  @override
  State<AuthField> createState() => _AuthFieldState();
}

class _AuthFieldState extends State<AuthField> {
  bool _obscured = true;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AuthLabel(widget.label),
        TextField(
          controller: widget.controller,
          keyboardType: widget.keyboardType,
          textInputAction: widget.textInputAction,
          obscureText: widget.isPassword && _obscured,
          cursorColor: EduColors.primary,
          style: const TextStyle(color: EduColors.textPrimary, fontSize: 14),
          decoration: authInputDecoration(
            hint: widget.hint,
            icon: widget.icon,
            suffix: widget.isPassword
                ? IconButton(
              icon: Icon(
                _obscured
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined,
                color: EduColors.textSecondary,
                size: 20,
              ),
              onPressed: () => setState(() => _obscured = !_obscured),
            )
                : null,
          ),
        ),
      ],
    );
  }
}

/// Tappable field that looks like an input (used for the programme picker).
class AuthPickerField extends StatelessWidget {
  final String label;
  final String placeholder;
  final String? value;
  final IconData icon;
  final VoidCallback onTap;

  const AuthPickerField({
    super.key,
    required this.label,
    required this.placeholder,
    required this.value,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final hasValue = value != null && value!.isNotEmpty;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AuthLabel(label),
        GestureDetector(
          onTap: onTap,
          child: Container(
            height: 54,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: hasValue ? EduColors.primarySoft : EduColors.background,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: hasValue ? EduColors.primary : EduColors.border,
              ),
            ),
            child: Row(
              children: [
                Icon(icon,
                    size: 20,
                    color:
                    hasValue ? EduColors.primary : EduColors.textSecondary),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    hasValue ? value! : placeholder,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: hasValue ? FontWeight.w700 : FontWeight.w400,
                      color: hasValue
                          ? EduColors.primary
                          : EduColors.textSecondary,
                    ),
                  ),
                ),
                const Icon(Icons.keyboard_arrow_down_rounded,
                    color: EduColors.textSecondary),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// Full-width primary button with a built-in loading spinner.
class AuthPrimaryButton extends StatelessWidget {
  final String label;
  final bool loading;
  final VoidCallback? onPressed;

  const AuthPrimaryButton({
    super.key,
    required this.label,
    required this.loading,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 54,
      width: double.infinity,
      child: ElevatedButton(
        onPressed: loading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: EduColors.primary,
          disabledBackgroundColor: const Color(0x993D5CFF),
          foregroundColor: EduColors.onPrimary,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(27),
          ),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
        ),
        child: loading
            ? const SizedBox(
          height: 22,
          width: 22,
          child: CircularProgressIndicator(
            color: EduColors.onPrimary,
            strokeWidth: 2.5,
          ),
        )
            : Text(label),
      ),
    );
  }
}

/// Full-width outlined secondary button.
class AuthSecondaryButton extends StatelessWidget {
  final String label;
  final IconData? icon;
  final VoidCallback onPressed;

  const AuthSecondaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 54,
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon ?? Icons.apartment_rounded, size: 20),
        label: Text(label),
        style: OutlinedButton.styleFrom(
          foregroundColor: EduColors.primary,
          side: const BorderSide(color: EduColors.primary, width: 1.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(27),
          ),
          textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
        ),
      ),
    );
  }
}

/// Red inline error box.
class AuthErrorBanner extends StatelessWidget {
  final String message;
  const AuthErrorBanner(this.message, {super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFDECEC),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline_rounded,
              color: EduColors.danger, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                color: EduColors.danger,
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Floating, themed snackbar used by auth screens.
void showAuthSnack(
    ScaffoldMessengerState messenger,
    String text, {
      bool isError = false,
    }) {
  messenger.showSnackBar(
    SnackBar(
      behavior: SnackBarBehavior.floating,
      backgroundColor: isError ? EduColors.danger : EduColors.textPrimary,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      content: Row(
        children: [
          Icon(
            isError ? Icons.error_outline_rounded : Icons.check_circle_rounded,
            color: isError ? EduColors.onPrimary : EduColors.success,
            size: 18,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(text, style: const TextStyle(color: EduColors.onPrimary)),
          ),
        ],
      ),
    ),
  );
}