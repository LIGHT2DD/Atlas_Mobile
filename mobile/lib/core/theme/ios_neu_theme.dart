import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Minimalist iOS-inspired Neumorphic (Soft UI) Monochromatic Tokens
class IosNeuColors {
  // Monochromatic Base Palette
  static const Color canvas = Color(0xFFE3E3E3);          // Warm stone gray for scaffolds, cards, sheets
  static const Color textPrimary = Color(0xFF2D2D2D);     // Deep matte charcoal for headings & glyphs
  static const Color textSecondary = Color(0xFF7E7E7E);   // SF Pro-styled muted gray for subtitles & counts
  static const Color activePill = Color(0xFF333333);      // High-contrast solid charcoal for active pills
  static const Color activeBadge = Color(0xFF555555);     // Inner badge circle inside active pills (white text)
  static const Color inactiveBadge = Color(0xFFD5D5D5);   // Inner badge circle inside unselected pills

  // Elevation Shadow Constants
  static const Color lightHighlight = Color(0xFFFFFFFF);  // Pure white top-left highlight
  static const Color darkShadow = Color(0xFFBFBFBF);      // Muted stone gray bottom-right shadow
  static const Color subtleHighlight = Color(0xFFFFFFFF); // Subtle highlight
  static const Color subtleShadow = Color(0xFFC8C8C8);    // Subtle shadow

  // Semantic Status Tones (Subtle Monochromatic / Soft Accents)
  static const Color statusNeutral = Color(0xFF4A4A4A);
  static const Color statusSuccess = Color(0xFF2E6F40);
  static const Color statusDanger = Color(0xFF992222);
  static const Color statusWarning = Color(0xFF8A6510);
  static const Color statusInfo = Color(0xFF334E68);
}

/// Global iOS Neumorphic Visual Theme Constants & Elevation Presets
class IosNeuTheme {
  static const Color canvas = IosNeuColors.canvas;
  static const Color textPrimary = IosNeuColors.textPrimary;
  static const Color textSecondary = IosNeuColors.textSecondary;
  static const Color activePill = IosNeuColors.activePill;
  static const Color activeBadge = IosNeuColors.activeBadge;
  static const Color inactiveBadge = IosNeuColors.inactiveBadge;

  /// Standard Elevation Shadows (Offset 5px, Blur 12px, Spread 1px)
  static List<BoxShadow> get standardShadows => const [
        BoxShadow(
          color: IosNeuColors.lightHighlight,
          offset: Offset(-5, -5),
          blurRadius: 12,
          spreadRadius: 1,
        ),
        BoxShadow(
          color: IosNeuColors.darkShadow,
          offset: Offset(5, 5),
          blurRadius: 12,
          spreadRadius: 1,
        ),
      ];

  /// Subtle Elevation Shadows (Offset 3px, Blur 8px)
  static List<BoxShadow> get subtleShadows => const [
        BoxShadow(
          color: IosNeuColors.subtleHighlight,
          offset: Offset(-3, -3),
          blurRadius: 8,
        ),
        BoxShadow(
          color: IosNeuColors.subtleShadow,
          offset: Offset(3, 3),
          blurRadius: 8,
        ),
      ];

  /// Dynamic depth generator with pure Soft UI proportions
  static List<BoxShadow> shadowsWithDepth(double depth) => [
        BoxShadow(
          color: IosNeuColors.lightHighlight.withValues(alpha: 0.95),
          offset: Offset(-1.25 * depth, -1.25 * depth),
          blurRadius: 3.0 * depth,
          spreadRadius: 0.25 * depth,
        ),
        BoxShadow(
          color: IosNeuColors.darkShadow.withValues(alpha: 0.8),
          offset: Offset(1.25 * depth, 1.25 * depth),
          blurRadius: 3.0 * depth,
          spreadRadius: 0.25 * depth,
        ),
      ];

  /// Soft convex gradient (extruded physical clay)
  static Gradient get convexGradient => const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Color(0xFFEBEBEB),
          Color(0xFFE3E3E3),
          Color(0xFFDCDCDC),
        ],
        stops: [0.0, 0.45, 1.0],
      );

  /// Soft concave gradient (sunken physical clay)
  static Gradient get concaveGradient => const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Color(0xFFD6D6D6),
          Color(0xFFE3E3E3),
          Color(0xFFEDEDED),
        ],
        stops: [0.0, 0.5, 1.0],
      );

  // Apple-inspired Typographic Hierarchy
  static const TextStyle largeTitle = TextStyle(
    fontSize: 34,
    fontWeight: FontWeight.w800,
    letterSpacing: -0.5,
    color: IosNeuColors.textPrimary,
  );

  static const TextStyle title1 = TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.w800,
    letterSpacing: -0.4,
    color: IosNeuColors.textPrimary,
  );

  static const TextStyle title2 = TextStyle(
    fontSize: 22,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.3,
    color: IosNeuColors.textPrimary,
  );

  static const TextStyle headline = TextStyle(
    fontSize: 17,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.2,
    color: IosNeuColors.textPrimary,
  );

  static const TextStyle body = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    letterSpacing: -0.1,
    color: IosNeuColors.textPrimary,
  );

  static const TextStyle subhead = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    letterSpacing: 0,
    color: IosNeuColors.textSecondary,
  );

  static const TextStyle caption = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w400,
    letterSpacing: 0.1,
    color: IosNeuColors.textSecondary,
  );

  /// System UI overlay configuration for seamless status and nav bars
  static const SystemUiOverlayStyle systemUiOverlayStyle = SystemUiOverlayStyle(
    statusBarColor: IosNeuColors.canvas,
    statusBarBrightness: Brightness.light,
    statusBarIconBrightness: Brightness.dark,
    systemNavigationBarColor: IosNeuColors.canvas,
    systemNavigationBarIconBrightness: Brightness.dark,
    systemNavigationBarDividerColor: Colors.transparent,
  );
}
