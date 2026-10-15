import 'package:flutter/material.dart';
import '../../core/theme/neumorphic_theme.dart';
import 'neu_container.dart';

/// Tactile Sunken Neumorphic Progress Bar
class NeuProgressBar extends StatelessWidget {
  final double progress; // 0.0 to 1.0
  final double height;
  final Color? fillColor;
  final String? label;
  final bool showPercentage;

  const NeuProgressBar({
    super.key,
    required this.progress,
    this.height = 14.0,
    this.fillColor,
    this.label,
    this.showPercentage = false,
  });

  @override
  Widget build(BuildContext context) {
    final neuTheme = context.neuTheme;
    final clampedProgress = progress.clamp(0.0, 1.0);
    final activeColor = fillColor ?? neuTheme.accentColor;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (label != null || showPercentage) ...[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              if (label != null)
                Text(
                  label!,
                  style: TextStyle(
                    color: neuTheme.textSecondary,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              if (showPercentage)
                Text(
                  '${(clampedProgress * 100).toInt()}%',
                  style: TextStyle(
                    color: activeColor,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 6),
        ],
        // Sunken recessed track
        NeuContainer(
          depthType: NeuDepth.concave,
          height: height,
          borderRadius: BorderRadius.circular(height / 2),
          padding: const EdgeInsets.all(2.5),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final fillWidth = constraints.maxWidth * clampedProgress;
              return Align(
                alignment: Alignment.centerLeft,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeOutCubic,
                  width: fillWidth,
                  height: height,
                  decoration: BoxDecoration(
                    color: activeColor,
                    borderRadius: BorderRadius.circular(height / 2),
                    gradient: LinearGradient(
                      colors: [
                        activeColor.withValues(alpha: 0.85),
                        activeColor,
                      ],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: activeColor.withValues(alpha: 0.35),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
