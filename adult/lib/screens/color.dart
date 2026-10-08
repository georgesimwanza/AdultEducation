import 'package:flutter/material.dart';

/// ─────────────────────────────────────────────────────────────
/// DESIGN TOKENS — shared by Dashboard, Schedule and Notice Board.
/// Replace these with the exact hex values from the EduLearn
/// Figma file (Colors panel). This is the only place to edit.
///
/// Save as: lib/theme/edu_colors.dart
/// ─────────────────────────────────────────────────────────────
class EduColors {
  static const primary = Color(0xFF3D5CFF); // main brand
  static const primaryDark = Color(0xFF2A3FB8); // gradient end / pressed
  static const primarySoft = Color(0xFFE8ECFF); // tinted backgrounds
  static const accent = Color(0xFFFF8A4C); // highlights, badges
  static const accentSoft = Color(0xFFFFEFE5);
  static const success = Color(0xFF2BB673);
  static const successSoft = Color(0xFFE3F6EC);
  static const danger = Color(0xFFE5484D);
  static const background = Color(0xFFF6F7FB);
  static const surface = Colors.white;
  static const textPrimary = Color(0xFF1B1D3A);
  static const textSecondary = Color(0xFF6E7191);
  static const border = Color(0xFFE6E8F2);
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