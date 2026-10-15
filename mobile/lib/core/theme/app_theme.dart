import 'package:flutter/material.dart';
import 'neumorphic_theme.dart';

class AppColors {
  // Brand Primary & Secondary (Neumorphic Aligned)
  static const Color primary = NeuColors.lightAccent;
  static const Color primaryLight = Color(0xFF6B8AFF);
  static const Color accent = NeuColors.lightAccent;
  static const Color accentLight = Color(0xFF8DA4FF);

  // Semantic Status Colors
  static const Color success = NeuColors.lightSuccess;
  static const Color successBg = Color(0xFFD1FAE5);
  static const Color warning = NeuColors.lightWarning;
  static const Color warningBg = Color(0xFFFEF3C7);
  static const Color error = NeuColors.lightDanger;
  static const Color errorBg = Color(0xFFFEE2E2);
  static const Color info = NeuColors.lightAccent;
  static const Color infoBg = Color(0xFFE0F2FE);

  // Background & Surface (Neumorphic Aligned)
  static const Color background = NeuColors.lightBase;
  static const Color surface = NeuColors.lightBase;
  static const Color card = NeuColors.lightBase;
  static const Color border = NeuColors.lightShadow;
  static const Color divider = Color(0xFFCAD1DC);

  // Typography
  static const Color textPrimary = NeuColors.lightTextPrimary;
  static const Color textSecondary = NeuColors.lightTextSecondary;
  static const Color textMuted = Color(0xFF8896AB);
}

class AppTheme {
  static ThemeData get lightTheme => neumorphicLightTheme;
  static ThemeData get darkTheme => neumorphicDarkTheme;

  /// Pure Neumorphic Light Theme
  static ThemeData get neumorphicLightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: NeuColors.lightBase,
      canvasColor: NeuColors.lightBase,
      cardColor: NeuColors.lightBase,
      dialogTheme: const DialogThemeData(
        backgroundColor: NeuColors.lightBase,
      ),
      colorScheme: const ColorScheme.light(
        primary: NeuColors.lightAccent,
        onPrimary: Colors.white,
        secondary: NeuColors.lightAccent,
        onSecondary: Colors.white,
        surface: NeuColors.lightBase,
        onSurface: NeuColors.lightTextPrimary,
        error: NeuColors.lightDanger,
        onError: Colors.white,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: NeuColors.lightBase,
        foregroundColor: NeuColors.lightTextPrimary,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: NeuColors.lightTextPrimary,
          fontSize: 18,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.2,
        ),
      ),
      textTheme: const TextTheme(
        headlineLarge: TextStyle(color: NeuColors.lightTextPrimary, fontWeight: FontWeight.w800),
        headlineMedium: TextStyle(color: NeuColors.lightTextPrimary, fontWeight: FontWeight.w700),
        titleLarge: TextStyle(color: NeuColors.lightTextPrimary, fontWeight: FontWeight.w700),
        titleMedium: TextStyle(color: NeuColors.lightTextPrimary, fontWeight: FontWeight.w600),
        bodyLarge: TextStyle(color: NeuColors.lightTextPrimary),
        bodyMedium: TextStyle(color: NeuColors.lightTextPrimary),
        bodySmall: TextStyle(color: NeuColors.lightTextSecondary),
      ),
      cardTheme: CardThemeData(
        color: NeuColors.lightBase,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 0),
      ),
      dividerTheme: const DividerThemeData(
        color: Color(0xFFD1D8E3),
        thickness: 1,
        space: 24,
      ),
    );
  }

  /// Pure Neumorphic Dark Theme
  static ThemeData get neumorphicDarkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: NeuColors.darkBase,
      canvasColor: NeuColors.darkBase,
      cardColor: NeuColors.darkBase,
      dialogTheme: const DialogThemeData(
        backgroundColor: NeuColors.darkBase,
      ),
      colorScheme: const ColorScheme.dark(
        primary: NeuColors.darkAccent,
        onPrimary: NeuColors.darkBase,
        secondary: NeuColors.darkAccent,
        onSecondary: NeuColors.darkBase,
        surface: NeuColors.darkBase,
        onSurface: NeuColors.darkTextPrimary,
        error: NeuColors.darkDanger,
        onError: Colors.white,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: NeuColors.darkBase,
        foregroundColor: NeuColors.darkTextPrimary,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: NeuColors.darkTextPrimary,
          fontSize: 18,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.2,
        ),
      ),
      textTheme: const TextTheme(
        headlineLarge: TextStyle(color: NeuColors.darkTextPrimary, fontWeight: FontWeight.w800),
        headlineMedium: TextStyle(color: NeuColors.darkTextPrimary, fontWeight: FontWeight.w700),
        titleLarge: TextStyle(color: NeuColors.darkTextPrimary, fontWeight: FontWeight.w700),
        titleMedium: TextStyle(color: NeuColors.darkTextPrimary, fontWeight: FontWeight.w600),
        bodyLarge: TextStyle(color: NeuColors.darkTextPrimary),
        bodyMedium: TextStyle(color: NeuColors.darkTextPrimary),
        bodySmall: TextStyle(color: NeuColors.darkTextSecondary),
      ),
      cardTheme: CardThemeData(
        color: NeuColors.darkBase,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 0),
      ),
      dividerTheme: const DividerThemeData(
        color: Color(0xFF353B42),
        thickness: 1,
        space: 24,
      ),
    );
  }
}
