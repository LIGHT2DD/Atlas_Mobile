import 'package:flutter/material.dart';
import '../../core/theme/neumorphic_theme.dart';
import 'neu_container.dart';

/// Soft Pill-Shaped Neumorphic Status Badge
class NeuBadge extends StatelessWidget {
  final String label;
  final Color? color;
  final bool isOverdue;
  final bool isSunken;
  final IconData? icon;

  const NeuBadge({
    super.key,
    required this.label,
    this.color,
    this.isOverdue = false,
    this.isSunken = true,
    this.icon,
  });

  /// Factory helper for generic Atlas status string
  factory NeuBadge.fromStatus(String status, {bool isOverdue = false}) {
    return NeuBadge(
      label: _formatStatus(status),
      color: _resolveStatusColor(status, isOverdue),
      isOverdue: isOverdue,
    );
  }

  static String _formatStatus(String status) {
    return status.replaceAll('_', ' ').split(' ').map((word) {
      if (word.isEmpty) return '';
      return word[0].toUpperCase() + word.substring(1).toLowerCase();
    }).join(' ');
  }

  static Color? _resolveStatusColor(String status, bool isOverdue) {
    if (isOverdue) return null; // Uses neuTheme.dangerColor

    final s = status.toUpperCase();
    if (s.contains('APPROV') || s.contains('COMPLET') || s.contains('ACTIVE')) {
      return const Color(0xFF38A169); // Emerald
    } else if (s.contains('REJECT') || s.contains('LATE') || s.contains('CANCEL')) {
      return const Color(0xFFE53E3E); // Crimson
    } else if (s.contains('CHANGE') || s.contains('PROGRESS') || s.contains('FORMING')) {
      return const Color(0xFFD69E2E); // Amber
    } else if (s.contains('SUBMIT') || s.contains('SCHEDULE')) {
      return const Color(0xFF3182CE); // Blue
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final neuTheme = context.neuTheme;
    final badgeColor = isOverdue
        ? neuTheme.dangerColor
        : (color ?? neuTheme.accentColor);

    return NeuContainer(
      depthType: isSunken ? NeuDepth.concave : NeuDepth.convex,
      depth: 2.0,
      borderRadius: BorderRadius.circular(20),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      border: Border.all(
        color: badgeColor.withValues(alpha: 0.3),
        width: 1,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(
              color: badgeColor,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: badgeColor.withValues(alpha: 0.6),
                  blurRadius: 4,
                  spreadRadius: 1,
                ),
              ],
            ),
          ),
          const SizedBox(width: 6),
          if (icon != null) ...[
            Icon(icon, size: 13, color: badgeColor),
            const SizedBox(width: 4),
          ],
          Text(
            isOverdue ? 'Overdue' : label,
            style: TextStyle(
              color: badgeColor,
              fontSize: 12,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }
}
