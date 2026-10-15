import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/theme/ios_neu_theme.dart';

/// Minimalist iOS Neumorphic Segment Filter Pill
class IosNeuSegmentPill extends StatelessWidget {
  final String label;
  final int? count;
  final bool isSelected;
  final VoidCallback onTap;
  final IconData? icon;

  const IosNeuSegmentPill({
    super.key,
    required this.label,
    this.count,
    required this.isSelected,
    required this.onTap,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final bgColor = isSelected ? IosNeuColors.activePill : IosNeuColors.canvas;
    final textColor = isSelected ? Colors.white : IosNeuColors.textPrimary;
    final badgeBg = isSelected ? IosNeuColors.activeBadge : IosNeuColors.inactiveBadge;
    final badgeTextColor = isSelected ? Colors.white : IosNeuColors.textPrimary;

    final shadows = isSelected
        ? [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.25),
              offset: const Offset(2, 4),
              blurRadius: 8,
            ),
          ]
        : IosNeuTheme.subtleShadows;

    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 9.0),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(28.0),
          boxShadow: shadows,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 16, color: textColor),
              const SizedBox(width: 6),
            ],
            Text(
              label,
              style: TextStyle(
                color: textColor,
                fontSize: 14,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                letterSpacing: -0.1,
              ),
            ),
            if (count != null) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: badgeBg,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  count.toString(),
                  style: TextStyle(
                    color: badgeTextColor,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Horizontal scrollable bar for iOS Neumorphic Segment Pills
class IosNeuSegmentBar<T> extends StatelessWidget {
  final List<T> items;
  final T selectedItem;
  final ValueChanged<T> onSelected;
  final String Function(T) labelBuilder;
  final int? Function(T)? countBuilder;
  final IconData? Function(T)? iconBuilder;
  final EdgeInsetsGeometry padding;

  const IosNeuSegmentBar({
    super.key,
    required this.items,
    required this.selectedItem,
    required this.onSelected,
    required this.labelBuilder,
    this.countBuilder,
    this.iconBuilder,
    this.padding = const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      padding: padding,
      child: Row(
        children: items.map((item) {
          final isSelected = item == selectedItem;
          return Padding(
            padding: const EdgeInsets.only(right: 10.0),
            child: IosNeuSegmentPill(
              label: labelBuilder(item),
              count: countBuilder?.call(item),
              icon: iconBuilder?.call(item),
              isSelected: isSelected,
              onTap: () => onSelected(item),
            ),
          );
        }).toList(),
      ),
    );
  }
}
