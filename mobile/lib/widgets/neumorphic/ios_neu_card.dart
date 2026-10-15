import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/theme/ios_neu_theme.dart';

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
    final effectiveRadius = shape == BoxShape.circle
        ? null
        : (borderRadius ?? BorderRadius.circular(isLarge ? 32.0 : 24.0));
    final effectiveColor = color ?? IosNeuColors.canvas;

    BoxDecoration decoration;
    if (isSunken) {
      decoration = BoxDecoration(
        color: effectiveColor,
        shape: shape,
        borderRadius: effectiveRadius,
        gradient: IosNeuTheme.concaveGradient,
        border: border ??
            Border.all(
              color: IosNeuColors.darkShadow.withValues(alpha: 0.35),
              width: 1.0,
            ),
      );
    } else {
      decoration = BoxDecoration(
        color: effectiveColor,
        shape: shape,
        borderRadius: effectiveRadius,
        gradient: IosNeuTheme.convexGradient,
        boxShadow: IosNeuTheme.standardShadows,
        border: border,
      );
    }

    Widget content = Container(
      width: width,
      height: height,
      margin: margin,
      padding: padding ?? const EdgeInsets.all(20.0),
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
        child: content,
      );
    }

    return content;
  }
}
