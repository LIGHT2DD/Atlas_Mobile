import 'package:flutter/material.dart';
import '../../core/theme/ios_neu_theme.dart';
import 'ios_neu_button.dart';

/// Minimalist iOS Neumorphic Empty State
/// Centered raised circular medallion (84x84 px) housing a minimalist line icon,
/// followed by a bold title, caption, and an extruded stadium action button.
class IosNeuEmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? message;
  final String? subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;
  final String? secondaryActionLabel;
  final VoidCallback? onSecondaryAction;

  const IosNeuEmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.message,
    this.subtitle,
    this.actionLabel,
    this.onAction,
    this.secondaryActionLabel,
    this.onSecondaryAction,
  });

  String get _description => subtitle ?? message ?? '';

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 28.0, vertical: 40.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Centered raised circular medallion (84x84 px)
            Container(
              width: 84.0,
              height: 84.0,
              decoration: BoxDecoration(
                color: IosNeuColors.canvas,
                shape: BoxShape.circle,
                gradient: IosNeuTheme.convexGradient,
                boxShadow: IosNeuTheme.standardShadows,
              ),
              alignment: Alignment.center,
              child: Icon(
                icon,
                size: 38.0,
                color: IosNeuColors.activePill,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.3,
                color: IosNeuColors.textPrimary,
              ),
            ),
            if (_description.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                _description,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                  height: 1.45,
                  color: IosNeuColors.textSecondary,
                ),
              ),
            ],
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 24),
              IosNeuButton(
                text: actionLabel!,
                onPressed: onAction,
                isPrimary: true,
                height: 48,
                borderRadius: BorderRadius.circular(24),
              ),
            ],
            if (secondaryActionLabel != null && onSecondaryAction != null) ...[
              const SizedBox(height: 12),
              IosNeuButton(
                text: secondaryActionLabel!,
                onPressed: onSecondaryAction,
                isPrimary: false,
                height: 44,
                borderRadius: BorderRadius.circular(22),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
