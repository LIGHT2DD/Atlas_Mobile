import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import '../../core/theme/ios_neu_theme.dart';

/// Minimalist iOS Neumorphic Floating Action Button
/// 64x64 px circular button with #E3E3E3 fill, prominent soft shadows, and a clean #333333 + icon (28px).
class IosNeuFAB extends StatefulWidget {
  final VoidCallback onPressed;
  final IconData icon;
  final String? tooltip;
  final double size;
  final double iconSize;

  const IosNeuFAB({
    super.key,
    required this.onPressed,
    this.icon = TablerIcons.plus,
    this.tooltip,
    this.size = 64.0,
    this.iconSize = 28.0,
  });

  @override
  State<IosNeuFAB> createState() => _IosNeuFABState();
}

class _IosNeuFABState extends State<IosNeuFAB> {
  bool _isPressed = false;

  void _onTapDown(TapDownDetails details) {
    HapticFeedback.lightImpact();
    setState(() => _isPressed = true);
  }

  void _onTapUp(TapUpDetails details) {
    if (_isPressed) setState(() => _isPressed = false);
  }

  void _onTapCancel() {
    if (_isPressed) setState(() => _isPressed = false);
  }

  @override
  Widget build(BuildContext context) {
    final shadows = _isPressed
        ? IosNeuTheme.shadowsWithDepth(1.2)
        : [
            const BoxShadow(
              color: IosNeuColors.lightHighlight,
              offset: Offset(-6, -6),
              blurRadius: 14,
              spreadRadius: 1,
            ),
            const BoxShadow(
              color: IosNeuColors.darkShadow,
              offset: Offset(6, 6),
              blurRadius: 14,
              spreadRadius: 1,
            ),
          ];

    Widget fab = GestureDetector(
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      onTap: widget.onPressed,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: widget.size,
        height: widget.size,
        decoration: BoxDecoration(
          color: IosNeuColors.canvas,
          shape: BoxShape.circle,
          gradient: _isPressed
              ? IosNeuTheme.concaveGradient
              : IosNeuTheme.convexGradient,
          boxShadow: shadows,
        ),
        alignment: Alignment.center,
        child: Icon(
          widget.icon,
          size: widget.iconSize,
          color: IosNeuColors.activePill,
        ),
      ),
    );

    if (widget.tooltip != null) {
      return Tooltip(message: widget.tooltip!, child: fab);
    }
    return fab;
  }
}
