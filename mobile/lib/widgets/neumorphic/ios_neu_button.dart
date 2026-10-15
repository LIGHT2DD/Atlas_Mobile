import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/theme/ios_neu_theme.dart';

/// Minimalist iOS Neumorphic Button with tactile depress dynamics & haptics
class IosNeuButton extends StatefulWidget {
  final Widget? child;
  final String? text;
  final IconData? icon;
  final VoidCallback? onPressed;
  final bool isLoading;
  final bool isPrimary;
  final bool isDanger;
  final double? width;
  final double height;
  final BorderRadius? borderRadius;
  final EdgeInsetsGeometry padding;

  const IosNeuButton({
    super.key,
    this.child,
    this.text,
    this.icon,
    required this.onPressed,
    this.isLoading = false,
    this.isPrimary = true,
    this.isDanger = false,
    this.width,
    this.height = 50.0,
    this.borderRadius,
    this.padding = const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
  });

  @override
  State<IosNeuButton> createState() => _IosNeuButtonState();
}

class _IosNeuButtonState extends State<IosNeuButton> {
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
    final isEnabled = widget.onPressed != null && !widget.isLoading;
    final effectiveRadius = widget.borderRadius ?? BorderRadius.circular(25.0);

    Color bgColor;
    Color contentColor;
    List<BoxShadow> shadows;

    if (widget.isDanger) {
      bgColor = widget.isPrimary ? IosNeuColors.statusDanger : IosNeuColors.canvas;
      contentColor = widget.isPrimary ? Colors.white : IosNeuColors.statusDanger;
      shadows = _isPressed
          ? []
          : [
              BoxShadow(
                color: IosNeuColors.statusDanger.withValues(alpha: 0.35),
                offset: const Offset(0, 4),
                blurRadius: 8,
              ),
            ];
    } else if (widget.isPrimary) {
      bgColor = IosNeuColors.activePill;
      contentColor = Colors.white;
      shadows = _isPressed
          ? [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.3),
                offset: const Offset(1, 2),
                blurRadius: 4,
              ),
            ]
          : [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.28),
                offset: const Offset(2, 5),
                blurRadius: 10,
              ),
              const BoxShadow(
                color: Colors.white24,
                offset: Offset(-2, -2),
                blurRadius: 6,
              ),
            ];
    } else {
      bgColor = IosNeuColors.canvas;
      contentColor = IosNeuColors.textPrimary;
      shadows = _isPressed ? IosNeuTheme.shadowsWithDepth(1.0) : IosNeuTheme.standardShadows;
    }

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
            Icon(widget.icon, size: 19, color: contentColor),
            if (widget.text != null) const SizedBox(width: 8),
          ],
          if (widget.text != null)
            Text(
              widget.text!,
              style: TextStyle(
                color: contentColor,
                fontSize: 15,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.2,
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
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        curve: Curves.easeInOut,
        width: widget.width,
        height: widget.height,
        padding: widget.padding,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: effectiveRadius,
          boxShadow: shadows,
        ),
        child: content,
      ),
    );
  }
}

/// Minimalist iOS Neumorphic Icon Button
class IosNeuIconButton extends StatefulWidget {
  final IconData icon;
  final VoidCallback? onPressed;
  final double size;
  final double iconSize;
  final Color? iconColor;
  final bool isCircle;
  final String? tooltip;
  final bool isSunken;

  const IosNeuIconButton({
    super.key,
    required this.icon,
    required this.onPressed,
    this.size = 46.0,
    this.iconSize = 21.0,
    this.iconColor,
    this.isCircle = true,
    this.tooltip,
    this.isSunken = false,
  });

  @override
  State<IosNeuIconButton> createState() => _IosNeuIconButtonState();
}

class _IosNeuIconButtonState extends State<IosNeuIconButton> {
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
    final color = widget.iconColor ?? IosNeuColors.textPrimary;
    final isEnabled = widget.onPressed != null;

    final List<BoxShadow> shadows = _isPressed
        ? IosNeuTheme.shadowsWithDepth(1.0)
        : (widget.isSunken ? const <BoxShadow>[] : IosNeuTheme.subtleShadows);

    Widget btn = GestureDetector(
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      onTap: isEnabled ? widget.onPressed : null,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: widget.size,
        height: widget.size,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: IosNeuColors.canvas,
          shape: widget.isCircle ? BoxShape.circle : BoxShape.rectangle,
          borderRadius: widget.isCircle ? null : BorderRadius.circular(16),
          boxShadow: shadows,
          gradient: widget.isSunken || _isPressed
              ? IosNeuTheme.concaveGradient
              : IosNeuTheme.convexGradient,
        ),
        child: Icon(
          widget.icon,
          size: widget.iconSize,
          color: isEnabled ? color : IosNeuColors.textSecondary.withValues(alpha: 0.5),
        ),
      ),
    );

    if (widget.tooltip != null) {
      return Tooltip(message: widget.tooltip!, child: btn);
    }
    return btn;
  }
}
