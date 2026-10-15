import 'package:flutter/material.dart';
import '../../core/theme/neumorphic_theme.dart';

/// Minimalist iOS Neumorphic Bottom Sheet
class IosNeuBottomSheet extends StatelessWidget {
  final Widget child;
  final String? title;
  final EdgeInsetsGeometry padding;

  const IosNeuBottomSheet({
    super.key,
    required this.child,
    this.title,
    this.padding = const EdgeInsets.fromLTRB(20, 12, 20, 24),
  });

  static Future<T?> show<T>({
    required BuildContext context,
    required Widget child,
    String? title,
    bool isDismissible = true,
    bool enableDrag = true,
  }) {
    return showModalBottomSheet<T>(
      context: context,
      isDismissible: isDismissible,
      enableDrag: enableDrag,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      elevation: 0,
      builder: (ctx) => IosNeuBottomSheet(
        title: title,
        child: child,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final neuTheme = context.neuTheme;
    final isDark = context.isDarkMode;

    return Container(
      decoration: BoxDecoration(
        color: neuTheme.baseColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32.0)),
        gradient: neuTheme.convexGradient,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.4 : 0.15),
            offset: const Offset(0, -4),
            blurRadius: 16,
          ),
          BoxShadow(
            color: neuTheme.darkShadow.withValues(alpha: isDark ? 0.3 : 0.2),
            offset: const Offset(0, -2),
            blurRadius: 10,
          ),
        ],
        border: isDark
            ? Border(
                top: BorderSide(color: neuTheme.darkHighlight.withValues(alpha: 0.35), width: 1.0),
              )
            : null,
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: padding,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Subtle top drag handle
              Center(
                child: Container(
                  width: 36,
                  height: 5,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: isDark ? neuTheme.darkHighlight : IosNeuColors.inactiveBadge,
                    borderRadius: BorderRadius.circular(2.5),
                  ),
                ),
              ),
              if (title != null) ...[
                Text(
                  title!,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.2,
                    color: neuTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 16),
              ],
              child,
            ],
          ),
        ),
      ),
    );
  }
}

/// Minimalist iOS Neumorphic Dialog
class IosNeuDialog extends StatelessWidget {
  final String title;
  final Widget? content;
  final String? message;
  final List<Widget>? actions;

  const IosNeuDialog({
    super.key,
    required this.title,
    this.content,
    this.message,
    this.actions,
  });

  static Future<T?> show<T>({
    required BuildContext context,
    required String title,
    String? message,
    Widget? content,
    List<Widget>? actions,
    bool barrierDismissible = true,
  }) {
    return showDialog<T>(
      context: context,
      barrierDismissible: barrierDismissible,
      barrierColor: Colors.black.withValues(alpha: 0.35),
      builder: (ctx) => IosNeuDialog(
        title: title,
        message: message,
        content: content,
        actions: actions,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final neuTheme = context.neuTheme;
    final isDark = context.isDarkMode;

    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: Container(
        decoration: BoxDecoration(
          color: neuTheme.baseColor,
          borderRadius: BorderRadius.circular(32.0),
          gradient: neuTheme.convexGradient,
          boxShadow: neuTheme.convexShadowsWithDepth(4.5),
          border: isDark
              ? Border.all(color: neuTheme.darkHighlight.withValues(alpha: 0.35), width: 0.8)
              : null,
        ),
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 19,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.3,
                color: neuTheme.textPrimary,
              ),
            ),
            if (message != null) ...[
              const SizedBox(height: 10),
              Text(
                message!,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                  height: 1.4,
                  color: neuTheme.textSecondary,
                ),
              ),
            ],
            if (content != null) ...[
              const SizedBox(height: 16),
              content!,
            ],
            if (actions != null && actions!.isNotEmpty) ...[
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: actions!.map((act) => Flexible(child: act)).toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
