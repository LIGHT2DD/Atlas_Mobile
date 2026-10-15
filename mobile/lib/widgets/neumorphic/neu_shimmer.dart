import 'package:flutter/material.dart';
import '../../core/theme/neumorphic_theme.dart';

/// Lightweight soft-UI skeleton loader with pulse animation
class NeuSkeletonCard extends StatefulWidget {
  final double height;
  final double width;
  final BorderRadius? borderRadius;
  final EdgeInsetsGeometry margin;

  const NeuSkeletonCard({
    super.key,
    this.height = 80.0,
    this.width = double.infinity,
    this.borderRadius,
    this.margin = const EdgeInsets.symmetric(vertical: 8.0),
  });

  @override
  State<NeuSkeletonCard> createState() => _NeuSkeletonCardState();
}

class _NeuSkeletonCardState extends State<NeuSkeletonCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.35, end: 0.85).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final neuTheme = context.neuTheme;
    final r = widget.borderRadius ?? BorderRadius.circular(16.0);

    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) {
        return Container(
          width: widget.width,
          height: widget.height,
          margin: widget.margin,
          decoration: BoxDecoration(
            color: Color.lerp(
              neuTheme.baseColor,
              neuTheme.darkShadow.withValues(alpha: 0.2),
              _pulseAnimation.value,
            ),
            borderRadius: r,
            boxShadow: [
              BoxShadow(
                color: neuTheme.darkShadow.withValues(alpha: 0.15 * _pulseAnimation.value),
                offset: const Offset(2, 2),
                blurRadius: 4,
              ),
              BoxShadow(
                color: neuTheme.highlightShadow.withValues(alpha: 0.4 * _pulseAnimation.value),
                offset: const Offset(-2, -2),
                blurRadius: 4,
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 140,
                  height: 12,
                  decoration: BoxDecoration(
                    color: neuTheme.textSecondary.withValues(alpha: 0.15 * _pulseAnimation.value),
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
                const SizedBox(height: 10),
                Container(
                  width: double.infinity,
                  height: 10,
                  decoration: BoxDecoration(
                    color: neuTheme.textSecondary.withValues(alpha: 0.08 * _pulseAnimation.value),
                    borderRadius: BorderRadius.circular(5),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
