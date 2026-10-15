import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/theme/neumorphic_theme.dart';
import 'neu_container.dart';

class NeuNavItem {
  final IconData icon;
  final String label;

  const NeuNavItem({
    required this.icon,
    required this.label,
  });
}

/// Floating Soft Neumorphic Bottom Navigation Bar
class NeuBottomNavBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  final List<NeuNavItem> items;

  const NeuBottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    final neuTheme = context.neuTheme;

    return Padding(
      padding: const EdgeInsets.only(left: 20, right: 20, bottom: 20, top: 8),
      child: NeuContainer(
        depthType: NeuDepth.convex,
        borderRadius: BorderRadius.circular(24.0),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: List.generate(items.length, (index) {
            final item = items[index];
            final isSelected = index == currentIndex;

            return GestureDetector(
              onTap: () {
                if (!isSelected) {
                  HapticFeedback.lightImpact();
                  onTap(index);
                }
              },
              behavior: HitTestBehavior.opaque,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: isSelected
                    ? BoxDecoration(
                        color: neuTheme.baseColor,
                        borderRadius: BorderRadius.circular(16),
                        gradient: neuTheme.concaveGradient,
                        border: Border.all(
                          color: neuTheme.darkShadow.withValues(alpha: 0.3),
                          width: 1,
                        ),
                      )
                    : null,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      item.icon,
                      size: 20,
                      color: isSelected ? neuTheme.accentColor : neuTheme.textSecondary,
                    ),
                    if (isSelected) ...[
                      const SizedBox(width: 8),
                      Text(
                        item.label,
                        style: TextStyle(
                          color: neuTheme.accentColor,
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            );
          }),
        ),
      ),
    );
  }
}
