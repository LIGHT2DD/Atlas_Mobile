import 'package:flutter/material.dart';
import '../../widgets/neumorphic/neu_badge.dart';

class StatusBadge extends StatelessWidget {
  final String status;
  final String? customLabel;
  final bool isOverdue;

  const StatusBadge({
    super.key,
    required this.status,
    this.customLabel,
    this.isOverdue = false,
  });

  @override
  Widget build(BuildContext context) {
    if (isOverdue) {
      return NeuBadge(
        label: customLabel ?? 'Overdue',
        isOverdue: true,
      );
    }

    final formatted = customLabel ?? NeuBadge.fromStatus(status).label;
    return NeuBadge(
      label: formatted,
      color: NeuBadge.fromStatus(status).color,
      isOverdue: isOverdue,
    );
  }
}
