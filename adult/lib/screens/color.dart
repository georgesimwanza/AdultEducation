import 'package:flutter/material.dart';

/// ─────────────────────────────────────────────────────────────
/// DESIGN TOKENS — shared by Dashboard, Schedule and Notice Board.
/// Replace these with the exact hex values from the EduLearn
/// Figma file (Colors panel). This is the only place to edit.
///
/// Save as: lib/theme/edu_colors.dart
/// ─────────────────────────────────────────────────────────────
class EduColors {
  /// Dark theme on or off. Set by AccessibilitySettings; the surface and
  /// text colours below follow it, brand colours stay the same.
  static bool dark = false;

  static const primary = Color(0xFF3D5CFF); // main brand
  static const primaryDark = Color(0xFF2A3FB8); // gradient end / pressed
  static Color get primarySoft =>
      dark ? const Color(0xFF262C55) : const Color(0xFFE8ECFF); // tinted backgrounds
  static const accent = Color(0xFFFF8A4C); // highlights, badges
  static Color get accentSoft => dark ? const Color(0xFF3D2A1E) : const Color(0xFFFFEFE5);
  static const success = Color(0xFF2BB673);
  static Color get successSoft => dark ? const Color(0xFF16332A) : const Color(0xFFE3F6EC);
  static const danger = Color(0xFFE5484D);
  static Color get background => dark ? const Color(0xFF10121F) : const Color(0xFFF6F7FB);
  static Color get surface => dark ? const Color(0xFF1B1E33) : Colors.white;
  static Color get textPrimary => dark ? const Color(0xFFECEEF8) : const Color(0xFF1B1D3A);
  static Color get textSecondary => dark ? const Color(0xFFA5A9C4) : const Color(0xFF6E7191);
  static Color get border => dark ? const Color(0xFF2E3250) : const Color(0xFFE6E8F2);

  /// Fixed dark backing for snackbars and the video panel, in both themes.
  static const ink = Color(0xFF1B1D3A);
  static const onPrimary = Colors.white;
  static const onPrimaryMuted = Color(0xB3FFFFFF); // white @ 70%
  static const onPrimaryFaint = Color(0x33FFFFFF); // white @ 20%

  static const List<BoxShadow> cardShadow = [
    BoxShadow(
      color: Color(0x143D5CFF),
      blurRadius: 20,
      offset: Offset(0, 8),
    ),
  ];
}