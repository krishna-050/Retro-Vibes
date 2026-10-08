import 'package:flutter/material.dart';
import '../provider/theme_provider.dart';

class AppTheme {
  // Background & Surface
  static Color scaffoldBackground = const Color(0xFF17120F);
  static Color cardBackground = const Color(0xFF211915);

  // Primary & Accent Colors
  static Color primaryAccent = const Color(0xFFB4662A);
  static Color unselectedItem = const Color(0xFF8F7962);
  static Color playerAccent = const Color(0xFFC85A32);
  static Color sliderInactive = const Color(0xFF3A2A23);

  // Yellow Palette
  static Color yellow100 = Colors.yellow.shade100;
  static Color yellow300 = Colors.yellow.shade300;
  static Color yellow50 = Colors.yellow.shade50;

  // Orange Palette
  static Color deepOrange = Colors.deepOrange;
  static Color deepOrangeAccent = Colors.deepOrangeAccent;
  static Color orange = Colors.orange;

  // White Shades
  static const Color white = Colors.white;
  static const Color white70 = Colors.white70;
  static const Color white10 = Colors.white10;
  static const Color white38 = Colors.white38;

  // Other Colors
  static const Color grey = Colors.grey;
  static const Color green = Colors.green;

  static ThemeData get themeData {
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: scaffoldBackground,
      cardColor: cardBackground,
      primaryColor: primaryAccent,
      colorScheme: ColorScheme.dark(
        primary: primaryAccent,
        surface: cardBackground,
        secondary: deepOrangeAccent,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: scaffoldBackground,
        elevation: 0,
      ),
    );
  }

  static void setTheme(RetroThemeType type) {
    switch (type) {
      case RetroThemeType.classic:
        scaffoldBackground = const Color(0xFF17120F);
        cardBackground = const Color(0xFF211915);
        primaryAccent = const Color(0xFFB4662A);
        unselectedItem = const Color(0xFF8F7962);
        playerAccent = const Color(0xFFC85A32);
        sliderInactive = const Color(0xFF3A2A23);
        yellow100 = Colors.yellow.shade100;
        yellow300 = Colors.yellow.shade300;
        yellow50 = Colors.yellow.shade50;
        deepOrange = Colors.deepOrange;
        deepOrangeAccent = Colors.deepOrangeAccent;
        orange = Colors.orange;
        break;

      case RetroThemeType.spiderMan:
        scaffoldBackground = const Color(0xFF0F080D);
        cardBackground = const Color(0xFF1E0C15);
        primaryAccent = const Color(0xFFE50914);
        unselectedItem = const Color(0xFF8A727D);
        playerAccent = const Color(0xFFE50914);
        sliderInactive = const Color(0xFF3D1823);
        yellow100 = const Color(0xFFFFD700);
        yellow300 = const Color(0xFFFFC107);
        yellow50 = const Color(0xFFFFF8E1);
        deepOrange = const Color(0xFFE50914);
        deepOrangeAccent = const Color(0xFFE50914);
        orange = const Color(0xFFE50914);
        break;
    }
  }
}
