import 'package:flutter/material.dart';
import '../../widgets/neumorphic/neumorphic.dart';

class EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? message;
  final String? subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;
  final String? secondaryActionLabel;
  final VoidCallback? onSecondaryAction;

  const EmptyState({
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

  String get _displayDescription => subtitle ?? message ?? '';

  @override
  Widget build(BuildContext context) {
    final neuTheme = context.neuTheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 48),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            NeuContainer(
              shape: BoxShape.circle,
              width: 84,
              height: 84,
              depthType: NeuDepth.convex,
              depth: 3.5,
              alignment: Alignment.center,
              child: Icon(icon, size: 38, color: neuTheme.accentColor),
            ),
            const SizedBox(height: 24),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: neuTheme.textPrimary,
                fontSize: 19,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.3,
              ),
            ),
            if (_displayDescription.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                _displayDescription,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: neuTheme.textSecondary,
                  fontSize: 14,
                  height: 1.45,
                ),
              ),
            ],
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 24),
              NeuButton(
                text: actionLabel!,
                isAccent: true,
                height: 48,
                borderRadius: BorderRadius.circular(24),
                onPressed: onAction,
              ),
            ],
            if (secondaryActionLabel != null && onSecondaryAction != null) ...[
              const SizedBox(height: 12),
              NeuButton(
                text: secondaryActionLabel!,
                height: 44,
                depth: 2.5,
                borderRadius: BorderRadius.circular(22),
                onPressed: onSecondaryAction,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
