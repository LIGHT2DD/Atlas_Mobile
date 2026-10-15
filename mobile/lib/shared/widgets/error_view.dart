import 'package:flutter/material.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import '../../widgets/neumorphic/neumorphic.dart';

class ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback? onRetry;

  const ErrorView({
    super.key,
    required this.message,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final neuTheme = context.neuTheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            NeuContainer(
              shape: BoxShape.circle,
              width: 76,
              height: 76,
              depthType: NeuDepth.convex,
              depth: 3.5,
              alignment: Alignment.center,
              child: Icon(TablerIcons.alert_circle, size: 36, color: neuTheme.dangerColor),
            ),
            const SizedBox(height: 20),
            Text(
              'Something went wrong',
              style: TextStyle(
                color: neuTheme.textPrimary,
                fontSize: 17,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: neuTheme.textSecondary,
                fontSize: 13,
                height: 1.4,
              ),
            ),
            if (onRetry != null) ...[
              const SizedBox(height: 24),
              NeuButton(
                text: 'Try Again',
                icon: TablerIcons.rotate_clockwise,
                height: 42,
                depth: 2.5,
                onPressed: onRetry,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
