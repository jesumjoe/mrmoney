import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsProvider with ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.system;
  ThemeMode get themeMode => _themeMode;

  SettingsProvider() {
    loadSettings();
  }

  Future<void> loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final themeIndex =
        prefs.getInt('themeMode') ?? 0; // 0: system, 1: light, 2: dark
    if (themeIndex == 1) {
      _themeMode = ThemeMode.light;
    } else if (themeIndex == 2)
      _themeMode = ThemeMode.dark;
    else
      _themeMode = ThemeMode.system;

    notifyListeners();
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    _themeMode = mode;
    int index = 0;
    if (_themeMode == ThemeMode.light) index = 1;
    if (_themeMode == ThemeMode.dark) index = 2;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('themeMode', index);
    notifyListeners();
  }

  void toggleTheme() {
    if (_themeMode == ThemeMode.light) {
      setThemeMode(ThemeMode.dark);
    } else if (_themeMode == ThemeMode.dark) {
      setThemeMode(ThemeMode.system);
    } else {
      setThemeMode(ThemeMode.light);
    }
  }
}
