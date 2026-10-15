import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/theme/neumorphic_theme.dart';

/// Minimalist iOS Neumorphic Card / Container with continuous curved geometry
class IosNeuCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final VoidCallback? onTap;
  final double? width;
  final double? height;
  final BorderRadius? borderRadius;
  final bool isLarge;
  final bool isSunken;
  final Color? color;
  final Border? border;
  final BoxShape shape;

  const IosNeuCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.onTap,
    this.width,
    this.height,
    this.borderRadius,
    this.isLarge = false,
    this.isSunken = false,
    this.color,
    this.border,
    this.shape = BoxShape.rectangle,
  });

  @override
  Widget build(BuildContext context) {
    final neuTheme = context.neuTheme;
    final isDark = context.isDarkMode;
    final effectiveRadius = shape == BoxShape.circle
        ? null
        : (borderRadius ?? BorderRadius.circular(isLarge ? 32.0 : 24.0));
    final effectiveColor = color ?? neuTheme.baseColor;

    BoxDecoration decoration;
    if (isSunken) {
      decoration = BoxDecoration(
        color: effectiveColor,
        shape: shape,
        borderRadius: effectiveRadius,
        gradient: neuTheme.concaveGradient,
        border: border ??
            Border.all(
              color: neuTheme.darkShadow.withValues(alpha: isDark ? 0.35 : 0.25),
              width: 1.0,
            ),
      );
    } else {
      decoration = BoxDecoration(
        color: effectiveColor,
        shape: shape,
        borderRadius: effectiveRadius,
        gradient: neuTheme.convexGradient,
        boxShadow: neuTheme.convexShadowsWithDepth(isLarge ? 4.5 : 3.5),
        border: border ??
            (isDark
                ? Border.all(
                    color: neuTheme.darkHighlight.withValues(alpha: 0.35),
                    width: 0.8,
                  )
                : null),
      );
    }

    Widget content = Container(
      width: width,
      height: height,
      margin: margin,
      padding: padding ?? const EdgeInsets.all(20.0),
      decoration: decoration,
      child: DefaultTextStyle.merge(
        style: TextStyle(color: neuTheme.textPrimary),
        child: IconTheme.merge(
          data: IconThemeData(color: neuTheme.textPrimary),
          child: child,
        ),
      ),
    );

    if (onTap != null) {
      return GestureDetector(
        onTap: () {
          HapticFeedback.lightImpact();
          onTap!();
        },
        behavior: HitTestBehavior.opaque,
        child: content,
      );
    }

    return content;
  }
}
