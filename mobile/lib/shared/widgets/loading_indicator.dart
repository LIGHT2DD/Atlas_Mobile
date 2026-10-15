import 'package:flutter/material.dart';
import '../../widgets/neumorphic/neumorphic.dart';

class LoadingIndicator extends StatelessWidget {
  final String? message;

  const LoadingIndicator({super.key, this.message});

  @override
  Widget build(BuildContext context) {
    final neuTheme = context.neuTheme;

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          NeuContainer(
            shape: BoxShape.circle,
            width: 64,
            height: 64,
            depthType: NeuDepth.convex,
            depth: 3.0,
            alignment: Alignment.center,
            child: SizedBox(
              width: 28,
              height: 28,
              child: CircularProgressIndicator(
                strokeWidth: 2.8,
                valueColor: AlwaysStoppedAnimation<Color>(neuTheme.accentColor),
              ),
            ),
          ),
          if (message != null) ...[
            const SizedBox(height: 18),
            Text(
              message!,
              style: TextStyle(
                color: neuTheme.textSecondary,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
