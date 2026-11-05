import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Device-wide reading preference: text size. Stored on the device so it
/// applies before sign-in too.
class AccessibilitySettings extends ChangeNotifier {
  static const _textKey = 'a11y_text_scale';

  /// 1.0 = normal, 1.2 = large, 1.4 = extra large
  double textScale = 1.0;

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    textScale = prefs.getDouble(_textKey) ?? 1.0;
    notifyListeners();
  }

  Future<void> setTextScale(double value) async {
    textScale = value;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_textKey, value);
  }
}
