import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import '../../core/theme/neumorphic_theme.dart';
import 'neu_container.dart';

/// Tactile Sunken Track + Extruded Thumb Neumorphic Switch
class NeuSwitch extends StatelessWidget {
  final bool value;
  final ValueChanged<bool> onChanged;
  final Color? activeColor;
  final double width;
  final double height;

  const NeuSwitch({
    super.key,
    required this.value,
    required this.onChanged,
    this.activeColor,
    this.width = 54.0,
    this.height = 30.0,
  });

  @override
  Widget build(BuildContext context) {
    final neuTheme = context.neuTheme;
    final thumbColor = value ? (activeColor ?? neuTheme.accentColor) : neuTheme.baseColor;
    final thumbSize = height - 6.0;

    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onChanged(!value);
      },
      behavior: HitTestBehavior.opaque,
      child: NeuContainer(
        width: width,
        height: height,
        depthType: NeuDepth.concave,
        borderRadius: BorderRadius.circular(height / 2),
        padding: const EdgeInsets.all(3.0),
        child: AnimatedAlign(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOut,
          alignment: value ? Alignment.centerRight : Alignment.centerLeft,
          child: NeuContainer(
            width: thumbSize,
            height: thumbSize,
            shape: BoxShape.circle,
            depthType: NeuDepth.convex,
            depth: 3.0,
            color: thumbColor,
            child: value
                ? Icon(
                    TablerIcons.check,
                    size: 14,
                    color: Colors.white,
                  )
                : null,
          ),
        ),
      ),
    );
  }
}

/// Tactile Sunken Neumorphic Checkbox
class NeuCheckbox extends StatelessWidget {
  final bool value;
  final ValueChanged<bool> onChanged;
  final Color? activeColor;
  final double size;

  const NeuCheckbox({
    super.key,
    required this.value,
    required this.onChanged,
    this.activeColor,
    this.size = 24.0,
  });

  @override
  Widget build(BuildContext context) {
    final neuTheme = context.neuTheme;
    final checkColor = activeColor ?? neuTheme.accentColor;

    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onChanged(!value);
      },
      behavior: HitTestBehavior.opaque,
      child: NeuContainer(
        width: size,
        height: size,
        depthType: value ? NeuDepth.convex : NeuDepth.concave,
        depth: value ? 3.0 : 2.0,
        borderRadius: BorderRadius.circular(6.0),
        alignment: Alignment.center,
        color: value ? checkColor : neuTheme.baseColor,
        child: value
            ? const Icon(
                TablerIcons.check,
                size: 16,
                color: Colors.white,
              )
            : null,
      ),
    );
  }
}
