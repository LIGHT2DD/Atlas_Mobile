import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/theme/neumorphic_theme.dart';
import 'neu_container.dart';

/// Tactile NeuButton with real physical press dynamics and haptics
class NeuButton extends StatefulWidget {
  final Widget? child;
  final String? text;
  final IconData? icon;
  final VoidCallback? onPressed;
  final bool isLoading;
  final bool isAccent;
  final bool isDanger;
  final double? width;
  final double height;
  final BorderRadius? borderRadius;
  final EdgeInsetsGeometry padding;
  final double depth;

  const NeuButton({
    super.key,
    this.child,
    this.text,
    this.icon,
    required this.onPressed,
    this.isLoading = false,
    this.isAccent = false,
    this.isDanger = false,
    this.width,
    this.height = 50.0,
    this.borderRadius,
    this.padding = const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
    this.depth = 4.0,
  });

  @override
  State<NeuButton> createState() => _NeuButtonState();
}

class _NeuButtonState extends State<NeuButton> {
  bool _isPressed = false;

  void _onTapDown(TapDownDetails details) {
    if (widget.onPressed == null || widget.isLoading) return;
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
    final neuTheme = context.neuTheme;
    final isEnabled = widget.onPressed != null && !widget.isLoading;

    Color buttonColor = neuTheme.baseColor;
    Color contentColor = widget.isAccent
        ? neuTheme.accentColor
        : (widget.isDanger ? neuTheme.dangerColor : neuTheme.textPrimary);

    if (widget.isAccent) {
      // Accent variant: base with accent glow
      contentColor = neuTheme.accentColor;
    }

    final depthState = _isPressed ? NeuDepth.concave : NeuDepth.convex;
    final currentDepth = _isPressed ? 1.0 : (isEnabled ? widget.depth : 1.5);

    Widget content;
    if (widget.isLoading) {
      content = SizedBox(
        width: 20,
        height: 20,
        child: CircularProgressIndicator(
          strokeWidth: 2.2,
          valueColor: AlwaysStoppedAnimation<Color>(contentColor),
        ),
      );
    } else if (widget.child != null) {
      content = widget.child!;
    } else {
      content = Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (widget.icon != null) ...[
            Icon(widget.icon, size: 20, color: contentColor),
            if (widget.text != null) const SizedBox(width: 8),
          ],
          if (widget.text != null)
            Text(
              widget.text!,
              style: TextStyle(
                color: contentColor,
                fontSize: 15,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.3,
              ),
            ),
        ],
      );
    }

    return GestureDetector(
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      onTap: isEnabled ? widget.onPressed : null,
      behavior: HitTestBehavior.opaque,
      child: NeuContainer(
        width: widget.width,
        height: widget.height,
        depthType: depthState,
        depth: currentDepth,
        color: buttonColor,
        borderRadius: widget.borderRadius ?? BorderRadius.circular(14.0),
        padding: widget.padding,
        alignment: Alignment.center,
        child: content,
      ),
    );
  }
}

/// Circular or Squircle Tactile Neumorphic Icon Button
class NeuIconButton extends StatefulWidget {
  final IconData icon;
  final VoidCallback? onPressed;
  final double size;
  final double iconSize;
  final Color? iconColor;
  final bool isCircle;
  final String? tooltip;
  final double depth;

  const NeuIconButton({
    super.key,
    required this.icon,
    required this.onPressed,
    this.size = 46.0,
    this.iconSize = 22.0,
    this.iconColor,
    this.isCircle = true,
    this.tooltip,
    this.depth = 3.5,
  });

  @override
  State<NeuIconButton> createState() => _NeuIconButtonState();
}

class _NeuIconButtonState extends State<NeuIconButton> {
  bool _isPressed = false;

  void _onTapDown(TapDownDetails details) {
    if (widget.onPressed == null) return;
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
    final neuTheme = context.neuTheme;
    final color = widget.iconColor ?? neuTheme.textPrimary;
    final isEnabled = widget.onPressed != null;

    Widget btn = GestureDetector(
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      onTap: isEnabled ? widget.onPressed : null,
      behavior: HitTestBehavior.opaque,
      child: NeuContainer(
        width: widget.size,
        height: widget.size,
        shape: widget.isCircle ? BoxShape.circle : BoxShape.rectangle,
        borderRadius: widget.isCircle ? null : BorderRadius.circular(12),
        depthType: _isPressed ? NeuDepth.concave : NeuDepth.convex,
        depth: _isPressed ? 1.0 : (isEnabled ? widget.depth : 1.5),
        alignment: Alignment.center,
        child: Icon(
          widget.icon,
          size: widget.iconSize,
          color: isEnabled ? color : neuTheme.textSecondary.withValues(alpha: 0.5),
        ),
      ),
    );

    if (widget.tooltip != null) {
      return Tooltip(message: widget.tooltip!, child: btn);
    }
    return btn;
  }
}
