import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/theme/neumorphic_theme.dart';

/// NeuContainer: Pure Flutter Soft-UI Extruded / Sunken Box
class NeuContainer extends StatelessWidget {
  final Widget? child;
  final NeuDepth depthType;
  final double depth;
  final BorderRadius? borderRadius;
  final BoxShape shape;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final Color? color;
  final Border? border;
  final VoidCallback? onTap;
  final double? width;
  final double height;
  final AlignmentGeometry? alignment;
  final Duration animationDuration;

  const NeuContainer({
    super.key,
    this.child,
    this.depthType = NeuDepth.convex,
    this.depth = 4.0,
    this.borderRadius,
    this.shape = BoxShape.rectangle,
    this.padding,
    this.margin,
    this.color,
    this.border,
    this.onTap,
    this.width,
    this.height = double.nan,
    this.alignment,
    this.animationDuration = const Duration(milliseconds: 150),
  });

  @override
  Widget build(BuildContext context) {
    final neuTheme = context.neuTheme;
    final effectiveColor = color ?? neuTheme.baseColor;
    final effectiveRadius = shape == BoxShape.circle
        ? null
        : (borderRadius ?? BorderRadius.circular(16.0));

    BoxDecoration decoration;

    switch (depthType) {
      case NeuDepth.convex:
        decoration = BoxDecoration(
          color: effectiveColor,
          shape: shape,
          borderRadius: effectiveRadius,
          gradient: neuTheme.convexGradient,
          boxShadow: neuTheme.convexShadowsWithDepth(depth),
          border: border,
        );
        break;

      case NeuDepth.flat:
        decoration = BoxDecoration(
          color: effectiveColor,
          shape: shape,
          borderRadius: effectiveRadius,
          border: border ??
              Border.all(
                color: neuTheme.darkShadow.withValues(alpha: neuTheme.isDark ? 0.3 : 0.2),
                width: 1,
              ),
        );
        break;

      case NeuDepth.concave:
        // Sunken effect: inverted soft gradient + subtle inner shade border
        decoration = BoxDecoration(
          color: effectiveColor,
          shape: shape,
          borderRadius: effectiveRadius,
          gradient: neuTheme.concaveGradient,
          border: border ??
              Border.all(
                color: neuTheme.darkShadow.withValues(alpha: neuTheme.isDark ? 0.45 : 0.25),
                width: 1.2,
              ),
        );
        break;
    }

    final effectiveHeight = height.isNaN ? null : height;

    Widget container = AnimatedContainer(
      duration: animationDuration,
      curve: Curves.easeInOut,
      width: width,
      height: effectiveHeight,
      margin: margin,
      padding: padding,
      alignment: alignment,
      decoration: decoration,
      child: child,
    );

    if (onTap != null) {
      return GestureDetector(
        onTap: () {
          HapticFeedback.lightImpact();
          onTap!();
        },
        behavior: HitTestBehavior.opaque,
        child: container,
      );
    }

    return container;
  }
}
