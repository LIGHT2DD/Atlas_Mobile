import 'package:flutter/material.dart';
import 'neumorphic_theme.dart';

class AppColors {
  // Monochromatic Brand Tones
  static const Color primary = IosNeuColors.activePill;       // #333333
  static const Color primaryLight = Color(0xFF555555);
  static const Color accent = IosNeuColors.activePill;        // #333333
  static const Color accentLight = Color(0xFF7E7E7E);

  // Subtle Semantic Status Colors
  static const Color success = IosNeuColors.statusSuccess;
  static const Color successBg = Color(0xFFD6E3D8);
  static const Color warning = IosNeuColors.statusWarning;
  static const Color warningBg = Color(0xFFEFE6D2);
  static const Color error = IosNeuColors.statusDanger;
  static const Color errorBg = Color(0xFFEEDCDA);
  static const Color info = IosNeuColors.statusInfo;
  static const Color infoBg = Color(0xFFDDE3EA);

  // Background & Surface
  static const Color background = IosNeuColors.canvas;        // #E3E3E3
  static const Color surface = IosNeuColors.canvas;           // #E3E3E3
  static const Color card = IosNeuColors.canvas;              // #E3E3E3
  static const Color border = IosNeuColors.darkShadow;        // #BFBFBF
  static const Color divider = Color(0xFFD0D0D0);

  // Typography
  static const Color textPrimary = IosNeuColors.textPrimary;  // #2D2D2D
  static const Color textSecondary = IosNeuColors.textSecondary; // #7E7E7E
  static const Color textMuted = Color(0xFF999999);
}

class AppTheme {
  static ThemeData get lightTheme => neumorphicLightTheme;
  static ThemeData get darkTheme => neumorphicDarkTheme;

  /// Apple-inspired Monochromatic Neumorphic Light Theme
  static ThemeData get neumorphicLightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: IosNeuColors.canvas,
      canvasColor: IosNeuColors.canvas,
      cardColor: IosNeuColors.canvas,
      dialogTheme: const DialogThemeData(
        backgroundColor: IosNeuColors.canvas,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(32)),
        ),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: IosNeuColors.canvas,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        ),
      ),
      colorScheme: const ColorScheme.light(
        primary: IosNeuColors.activePill,
        onPrimary: Colors.white,
        secondary: IosNeuColors.activePill,
        onSecondary: Colors.white,
        surface: IosNeuColors.canvas,
        onSurface: IosNeuColors.textPrimary,
        error: IosNeuColors.statusDanger,
        onError: Colors.white,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: IosNeuColors.canvas,
        foregroundColor: IosNeuColors.textPrimary,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        systemOverlayStyle: IosNeuTheme.systemUiOverlayStyle,
        titleTextStyle: TextStyle(
          color: IosNeuColors.textPrimary,
          fontSize: 20,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.3,
        ),
      ),
      textTheme: const TextTheme(
        headlineLarge: IosNeuTheme.largeTitle,
        headlineMedium: IosNeuTheme.title1,
        titleLarge: IosNeuTheme.title2,
        titleMedium: IosNeuTheme.headline,
        bodyLarge: IosNeuTheme.body,
        bodyMedium: TextStyle(color: IosNeuColors.textPrimary, fontSize: 15),
        bodySmall: IosNeuTheme.caption,
      ),
      cardTheme: CardThemeData(
        color: IosNeuColors.canvas,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 0),
      ),
      dividerTheme: const DividerThemeData(
        color: Color(0xFFD4D4D4),
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
