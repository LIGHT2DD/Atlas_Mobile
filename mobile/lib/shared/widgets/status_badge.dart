import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

class StatusBadge extends StatelessWidget {
  final String status;
  final String? customLabel;

  const StatusBadge({
    super.key,
    required this.status,
    this.customLabel,
  });

  @override
  Widget build(BuildContext context) {
    final (label, bgColor, textColor) = _resolveStyle(status);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        customLabel ?? label,
        style: TextStyle(
          color: textColor,
          fontSize: 12,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.2,
        ),
      ),
    );
  }

  (String, Color, Color) _resolveStyle(String s) {
    switch (s.toLowerCase().replaceAll(' ', '_')) {
      case 'forming':
        return ('Forming', const Color(0xFFE2E8F0), const Color(0xFF475569));
      case 'supervisor_requested':
        return ('Supervisor Requested', AppColors.warningBg, const Color(0xFFB45309));
      case 'supervisor_assigned':
        return ('Supervisor Assigned', AppColors.infoBg, const Color(0xFF0369A1));
      case 'pending':
        return ('Pending', AppColors.warningBg, const Color(0xFFB45309));
      case 'proposal_approved':
      case 'approved':
        return ('Approved', AppColors.successBg, const Color(0xFF047857));
      case 'submitted':
      case 'under_review':
        return ('Submitted', AppColors.infoBg, const Color(0xFF0284C7));
      case 'changes_requested':
      case 'revision_required':
        return ('Changes Requested', AppColors.warningBg, const Color(0xFFD97706));
      case 'rejected':
      case 'cancelled':
        return ('Rejected', AppColors.errorBg, const Color(0xFFB91C1C));
      case 'late':
        return ('Late Submission', AppColors.errorBg, const Color(0xFFDC2626));
      case 'reviewed':
        return ('Graded', AppColors.successBg, const Color(0xFF065F46));
      case 'completed':
        return ('Completed', const Color(0xFFEDE9FE), const Color(0xFF6D28D9));
      case 'scheduled':
        return ('Scheduled', AppColors.infoBg, const Color(0xFF0284C7));
      default:
        return (s.toUpperCase(), AppColors.divider, AppColors.textSecondary);
    }
  }
}
