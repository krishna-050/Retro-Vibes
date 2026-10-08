import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme/app_theme.dart';

enum RetroThemeType {
  classic,
  spiderMan,
}

class ThemeProvider extends ChangeNotifier {
  RetroThemeType _currentTheme = RetroThemeType.classic;

  RetroThemeType get currentTheme => _currentTheme;

  String get themeName {
    switch (_currentTheme) {
      case RetroThemeType.classic:
        return 'Classic Retro (Default)';
      case RetroThemeType.spiderMan:
        return 'Spider-Man Dark Red';
    }
  }

  ThemeProvider() {
    _loadTheme();
  }

  Future<void> _loadTheme() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final themeIndex = prefs.getInt('retro_theme_index') ?? 0;
      if (themeIndex >= 0 && themeIndex < RetroThemeType.values.length) {
        _currentTheme = RetroThemeType.values[themeIndex];
        AppTheme.setTheme(_currentTheme);
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error loading theme: $e');
    }
  }

  Future<void> setTheme(RetroThemeType type) async {
    if (_currentTheme == type) return;
    _currentTheme = type;
    AppTheme.setTheme(type);

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('retro_theme_index', type.index);
    } catch (e) {
      debugPrint('Error saving theme: $e');
    }

    notifyListeners();
  }
}
