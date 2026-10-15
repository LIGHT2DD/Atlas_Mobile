import 'package:flutter/material.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import '../../core/theme/neumorphic_theme.dart';
import 'neu_container.dart';

enum NeuToastType { info, success, warning, error }

/// Floating Neumorphic Toast Banner with dual soft shadows
class NeuToast {
  static void show(
    BuildContext context, {
    required String message,
    String? title,
    NeuToastType type = NeuToastType.info,
    Duration duration = const Duration(seconds: 4),
  }) {
    final overlayState = Overlay.of(context);
    late OverlayEntry overlayEntry;

    overlayEntry = OverlayEntry(
      builder: (ctx) => _NeuToastWidget(
        title: title,
        message: message,
        type: type,
        onDismiss: () {
          if (overlayEntry.mounted) {
            overlayEntry.remove();
          }
        },
      ),
    );

    overlayState.insert(overlayEntry);

    Future.delayed(duration, () {
      if (overlayEntry.mounted) {
        overlayEntry.remove();
      }
    });
  }
}

class _NeuToastWidget extends StatefulWidget {
  final String? title;
  final String message;
  final NeuToastType type;
  final VoidCallback onDismiss;

  const _NeuToastWidget({
    this.title,
    required this.message,
    required this.type,
    required this.onDismiss,
  });

  @override
  State<_NeuToastWidget> createState() => _NeuToastWidgetState();
}

class _NeuToastWidgetState extends State<_NeuToastWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
    _fadeAnimation = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, -0.6),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final neuTheme = context.neuTheme;

    Color typeColor;
    IconData typeIcon;

    switch (widget.type) {
      case NeuToastType.success:
        typeColor = neuTheme.successColor;
        typeIcon = TablerIcons.circle_check;
        break;
      case NeuToastType.warning:
        typeColor = neuTheme.warningColor;
        typeIcon = TablerIcons.alert_triangle;
        break;
      case NeuToastType.error:
        typeColor = neuTheme.dangerColor;
        typeIcon = TablerIcons.alert_circle;
        break;
      case NeuToastType.info:
        typeColor = neuTheme.accentColor;
        typeIcon = TablerIcons.info_circle;
        break;
    }

    return SafeArea(
      child: Align(
        alignment: Alignment.topCenter,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: SlideTransition(
            position: _slideAnimation,
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: Material(
                color: Colors.transparent,
                child: NeuContainer(
                  depthType: NeuDepth.convex,
                  depth: 5.0,
                  borderRadius: BorderRadius.circular(16),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  border: Border.all(color: typeColor.withValues(alpha: 0.35), width: 1.2),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: typeColor.withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(typeIcon, color: typeColor, size: 22),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (widget.title != null) ...[
                              Text(
                                widget.title!,
                                style: TextStyle(
                                  color: neuTheme.textPrimary,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 2),
                            ],
                            Text(
                              widget.message,
                              style: TextStyle(
                                color: neuTheme.textSecondary,
                                fontSize: 13,
                                height: 1.3,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: Icon(TablerIcons.x, size: 18, color: neuTheme.textSecondary),
                        onPressed: widget.onDismiss,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
