import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../storage/secure_storage.dart';

/// Neumorphism Color Palette & Theme Tokens
/// Background and surface colors are identical so elements appear
/// physically extruded from or pressed into the same continuous material.
export 'ios_neu_theme.dart';

class NeuColors {
  // Light Mode Tokens (Apple-Inspired Monochromatic Soft UI)
  static const Color lightBase = Color(0xFFE3E3E3);           // Base warm stone gray
  static const Color lightHighlight = Color(0xFFFFFFFF);      // Pure white top-left highlight
  static const Color lightShadow = Color(0xFFBFBFBF);         // Muted stone gray bottom-right shadow
  static const Color lightTextPrimary = Color(0xFF2D2D2D);    // Deep matte charcoal primary text
  static const Color lightTextSecondary = Color(0xFF7E7E7E);  // SF Pro-styled muted gray text
  static const Color lightAccent = Color(0xFF333333);         // High-contrast solid charcoal
  static const Color lightDanger = Color(0xFF992222);         // Muted crimson
  static const Color lightSuccess = Color(0xFF2E6F40);        // Muted forest green
  static const Color lightWarning = Color(0xFF8A6510);        // Muted bronze amber

  // Dark Mode Tokens
  static const Color darkBase = Color(0xFF292D32);            // Deep matte charcoal surface
  static const Color darkHighlight = Color(0xFF353B42);       // Subtle top-left highlight
  static const Color darkShadow = Color(0xFF1D2024);          // Deep bottom-right shadow
  static const Color darkTextPrimary = Color(0xFFE2E8F0);     // Crisp light primary text
  static const Color darkTextSecondary = Color(0xFFA0AEC0);   // Muted slate secondary text
  static const Color darkAccent = Color(0xFF63B3ED);          // Glowing Soft Sky / Indigo
  static const Color darkDanger = Color(0xFFFC8181);          // Coral Crimson
  static const Color darkSuccess = Color(0xFF68D391);         // Mint Emerald
  static const Color darkWarning = Color(0xFFF6E05E);         // Warm Gold
}

enum NeuDepth {
  convex,   // Extruded / Raised above the surface
  flat,     // Flat surface with subtle border
  concave,  // Sunken / Carved / Pressed into the surface
}

class NeumorphicThemeData {
  final bool isDark;
  final Color baseColor;
  final Color highlightShadow;
  final Color darkShadow;
  final Color textPrimary;
  final Color textSecondary;
  final Color accentColor;
  final Color dangerColor;
  final Color successColor;
  final Color warningColor;
  final Offset highlightOffset;
  final Offset darkOffset;
  final double blurRadius;

  Color get darkHighlight => highlightShadow;

  const NeumorphicThemeData({
    required this.isDark,
    required this.baseColor,
    required this.highlightShadow,
    required this.darkShadow,
    required this.textPrimary,
    required this.textSecondary,
    required this.accentColor,
    required this.dangerColor,
    required this.successColor,
    required this.warningColor,
    required this.highlightOffset,
    required this.darkOffset,
    required this.blurRadius,
  });

  static const light = NeumorphicThemeData(
    isDark: false,
    baseColor: NeuColors.lightBase,
    highlightShadow: NeuColors.lightHighlight,
    darkShadow: NeuColors.lightShadow,
    textPrimary: NeuColors.lightTextPrimary,
    textSecondary: NeuColors.lightTextSecondary,
    accentColor: NeuColors.lightAccent,
    dangerColor: NeuColors.lightDanger,
    successColor: NeuColors.lightSuccess,
    warningColor: NeuColors.lightWarning,
    highlightOffset: Offset(-5, -5),
    darkOffset: Offset(5, 5),
    blurRadius: 12.0,
  );

  static const dark = NeumorphicThemeData(
    isDark: true,
    baseColor: NeuColors.darkBase,
    highlightShadow: NeuColors.darkHighlight,
    darkShadow: NeuColors.darkShadow,
    textPrimary: NeuColors.darkTextPrimary,
    textSecondary: NeuColors.darkTextSecondary,
    accentColor: NeuColors.darkAccent,
    dangerColor: NeuColors.darkDanger,
    successColor: NeuColors.darkSuccess,
    warningColor: NeuColors.darkWarning,
    highlightOffset: Offset(-5, -5),
    darkOffset: Offset(5, 5),
    blurRadius: 10.0,
  );

  /// Generate dual BoxShadow for convex / extruded surfaces
  List<BoxShadow> get convexShadows => [
        BoxShadow(
          color: highlightShadow.withValues(alpha: isDark ? 0.25 : 0.85),
          offset: highlightOffset,
          blurRadius: blurRadius,
        ),
        BoxShadow(
          color: darkShadow.withValues(alpha: isDark ? 0.35 : 0.22),
          offset: darkOffset,
          blurRadius: blurRadius,
        ),
      ];

  /// Generate dual BoxShadow with customized depth multiplier
  List<BoxShadow> convexShadowsWithDepth(double depth) => [
        BoxShadow(
          color: highlightShadow.withValues(alpha: isDark ? 0.25 : 0.85),
          offset: highlightOffset * (depth / 4.0),
          blurRadius: blurRadius * (depth / 4.0),
        ),
        BoxShadow(
          color: darkShadow.withValues(alpha: isDark ? 0.35 : 0.22),
          offset: darkOffset * (depth / 4.0),
          blurRadius: blurRadius * (depth / 4.0),
        ),
      ];

  /// Gradient simulating a concave / sunken surface
  Gradient get concaveGradient => LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          darkShadow.withValues(alpha: isDark ? 0.20 : 0.10),
          baseColor,
          highlightShadow.withValues(alpha: isDark ? 0.12 : 0.45),
        ],
        stops: const [0.0, 0.5, 1.0],
      );

  /// Subtle gradient simulating a convex / extruded surface
  Gradient get convexGradient => LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          highlightShadow.withValues(alpha: isDark ? 0.15 : 0.35),
          baseColor,
          darkShadow.withValues(alpha: isDark ? 0.3 : 0.15),
        ],
        stops: const [0.0, 0.4, 1.0],
      );
}

/// Global ThemeMode Riverpod Notifier for Light/Dark toggling with SecureStorage persistence
class ThemeModeNotifier extends StateNotifier<ThemeMode> {
  final SecureStorageService? _storage;

  ThemeModeNotifier([this._storage]) : super(ThemeMode.light) {
    _loadSavedTheme();
  }

  Future<void> _loadSavedTheme() async {
    if (_storage == null) return;
    try {
      final saved = await _storage.getThemeMode();
      if (saved == 'dark') {
        state = ThemeMode.dark;
      } else if (saved == 'light') {
        state = ThemeMode.light;
      } else if (saved == 'system') {
        state = ThemeMode.system;
      }
    } catch (_) {}
  }

  void toggleTheme() {
    final next = state == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
    setTheme(next);
  }

  void setTheme(ThemeMode mode) {
    state = mode;
    _persistTheme(mode);
  }

  void _persistTheme(ThemeMode mode) {
    if (_storage == null) return;
    final value = mode == ThemeMode.dark
        ? 'dark'
        : mode == ThemeMode.light
            ? 'light'
            : 'system';
    _storage.saveThemeMode(value);
  }

  bool get isDarkMode => state == ThemeMode.dark;
}

final themeModeProvider = StateNotifierProvider<ThemeModeNotifier, ThemeMode>((ref) {
  final storage = ref.watch(secureStorageProvider);
  return ThemeModeNotifier(storage);
});

/// Context extension for quick neumorphic theme resolution in any build method
extension NeumorphicContextExt on BuildContext {
  bool get isDarkMode {
    final brightness = Theme.of(this).brightness;
    return brightness == Brightness.dark;
  }

  NeumorphicThemeData get neuTheme =>
      isDarkMode ? NeumorphicThemeData.dark : NeumorphicThemeData.light;
}
