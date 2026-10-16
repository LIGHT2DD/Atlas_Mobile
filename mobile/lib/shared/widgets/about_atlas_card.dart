import 'package:flutter/material.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import '../../widgets/neumorphic/neumorphic.dart';

class AboutAtlasCard extends StatelessWidget {
  final bool isCompact;

  const AboutAtlasCard({
    super.key,
    this.isCompact = false,
  });

  @override
  Widget build(BuildContext context) {
    final neuTheme = context.neuTheme;

    return NeuContainer(
      depthType: NeuDepth.convex,
      depth: isCompact ? 2.0 : 3.0,
      borderRadius: BorderRadius.circular(isCompact ? 16 : 20),
      padding: EdgeInsets.symmetric(
        horizontal: isCompact ? 14 : 18,
        vertical: isCompact ? 12 : 16,
      ),
      border: neuTheme.isDark
          ? Border.all(
              color: neuTheme.darkHighlight.withValues(alpha: 0.25),
              width: 0.8,
            )
          : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              NeuContainer(
                shape: BoxShape.circle,
                width: isCompact ? 24 : 28,
                height: isCompact ? 24 : 28,
                depthType: NeuDepth.convex,
                depth: 1.5,
                alignment: Alignment.center,
                child: Icon(
                  TablerIcons.info_circle,
                  size: isCompact ? 14 : 16,
                  color: neuTheme.accentColor,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'ABOUT ATLAS',
                style: TextStyle(
                  color: neuTheme.accentColor,
                  fontSize: isCompact ? 11 : 12,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.8,
                ),
              ),
            ],
          ),
          SizedBox(height: isCompact ? 6 : 8),
          Text(
            'Academic Thesis Lifecycle & Assessment Suite',
            style: TextStyle(
              color: neuTheme.textPrimary,
              fontSize: isCompact ? 12 : 14,
              fontWeight: FontWeight.w700,
              height: 1.25,
            ),
          ),
          SizedBox(height: isCompact ? 4 : 6),
          Text(
            'A centralized academic platform coordinating thesis proposals, milestone deliverables, oral defense hearings, and rubric evaluations for students, supervisors, and coordinators.',
            style: TextStyle(
              color: neuTheme.textSecondary,
              fontSize: isCompact ? 11 : 12,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}
