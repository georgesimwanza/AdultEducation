import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:adult/screens/color.dart';

/// Device-wide display preferences: text size and theme. Stored on the
/// device so they apply before sign-in too.
class AccessibilitySettings extends ChangeNotifier {
  static const _textKey = 'a11y_text_scale';
  static const _themeKey = 'theme_mode';

  /// 1.0 = normal, 1.2 = large, 1.4 = extra large
  double textScale = 1.0;

  /// Light by default; [ThemeMode.system] follows the device setting.
  ThemeMode themeMode = ThemeMode.light;

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    textScale = prefs.getDouble(_textKey) ?? 1.0;
    themeMode = ThemeMode.values.firstWhere(
      (m) => m.name == prefs.getString(_themeKey),
      orElse: () => ThemeMode.light,
    );
    _applyTheme();
    // Follow the device if it switches while the app is open.
    WidgetsBinding.instance.platformDispatcher.onPlatformBrightnessChanged = () {
      if (themeMode == ThemeMode.system) {
        _applyTheme();
        notifyListeners();
      }
    };
    notifyListeners();
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    themeMode = mode;
    _applyTheme();
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_themeKey, mode.name);
  }

  void _applyTheme() {
    final deviceDark =
        WidgetsBinding.instance.platformDispatcher.platformBrightness == Brightness.dark;
    EduColors.dark =
        themeMode == ThemeMode.dark || (themeMode == ThemeMode.system && deviceDark);
  }

  Future<void> setTextScale(double value) async {
    textScale = value;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_textKey, value);
  }
}
