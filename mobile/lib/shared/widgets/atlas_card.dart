import 'package:flutter/material.dart';
import '../../widgets/neumorphic/neu_container.dart';
import '../../core/theme/neumorphic_theme.dart';

class AtlasCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final VoidCallback? onTap;
  final Color? color;
  final double depth;
  final BorderRadius? borderRadius;
  final NeuDepth depthType;

  const AtlasCard({
    super.key,
    required this.child,
    this.padding,
    this.onTap,
    this.color,
    this.depth = 3.5,
    this.borderRadius,
    this.depthType = NeuDepth.convex,
  });

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: NeuContainer(
        depthType: depthType,
        depth: depth,
        borderRadius: borderRadius ?? BorderRadius.circular(24),
        color: color,
        padding: padding ?? const EdgeInsets.all(20),
        onTap: onTap,
        child: child,
      ),
    );
  }
}
