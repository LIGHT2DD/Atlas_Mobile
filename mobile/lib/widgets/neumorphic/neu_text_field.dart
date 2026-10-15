import 'package:flutter/material.dart';
import '../../core/theme/neumorphic_theme.dart';
import 'neu_container.dart';

/// Sunken / Carved-in Neumorphic Text Field
class NeuTextField extends StatefulWidget {
  final TextEditingController? controller;
  final String? labelText;
  final String? hintText;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final bool obscureText;
  final TextInputType keyboardType;
  final String? Function(String?)? validator;
  final void Function(String)? onChanged;
  final void Function(String)? onFieldSubmitted;
  final int maxLines;
  final bool readOnly;
  final VoidCallback? onTap;
  final FocusNode? focusNode;
  final Iterable<String>? autofillHints;

  const NeuTextField({
    super.key,
    this.controller,
    this.labelText,
    this.hintText,
    this.prefixIcon,
    this.suffixIcon,
    this.obscureText = false,
    this.keyboardType = TextInputType.text,
    this.validator,
    this.onChanged,
    this.onFieldSubmitted,
    this.maxLines = 1,
    this.readOnly = false,
    this.onTap,
    this.focusNode,
    this.autofillHints,
  });

  @override
  State<NeuTextField> createState() => _NeuTextFieldState();
}

class _NeuTextFieldState extends State<NeuTextField> {
  String? _errorText;

  @override
  Widget build(BuildContext context) {
    final neuTheme = context.neuTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.labelText != null) ...[
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 8),
            child: Text(
              widget.labelText!,
              style: TextStyle(
                color: neuTheme.textSecondary,
                fontSize: 13,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.2,
              ),
            ),
          ),
        ],
        // Sunken recessed input container
        NeuContainer(
          depthType: NeuDepth.concave,
          borderRadius: BorderRadius.circular(14),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          border: _errorText != null
              ? Border.all(color: neuTheme.dangerColor.withValues(alpha: 0.8), width: 1.2)
              : null,
          child: TextFormField(
            controller: widget.controller,
            focusNode: widget.focusNode,
            autofillHints: widget.autofillHints,
            obscureText: widget.obscureText,
            keyboardType: widget.keyboardType,
            maxLines: widget.maxLines,
            readOnly: widget.readOnly,
            onTap: widget.onTap,
            onChanged: (val) {
              if (_errorText != null) {
                setState(() => _errorText = null);
              }
              widget.onChanged?.call(val);
            },
            onFieldSubmitted: widget.onFieldSubmitted,
            validator: (val) {
              final err = widget.validator?.call(val);
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted && _errorText != err) {
                  setState(() => _errorText = err);
                }
              });
              return err != null ? '' : null; // Suppress default error line inside
            },
            style: TextStyle(
              color: neuTheme.textPrimary,
              fontSize: 15,
              fontWeight: FontWeight.w500,
            ),
            decoration: InputDecoration(
              isDense: true,
              hintText: widget.hintText,
              hintStyle: TextStyle(
                color: neuTheme.textSecondary.withValues(alpha: 0.65),
                fontSize: 14,
              ),
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              errorBorder: InputBorder.none,
              focusedErrorBorder: InputBorder.none,
              errorStyle: const TextStyle(height: 0, fontSize: 0),
              prefixIcon: widget.prefixIcon != null
                  ? Padding(
                      padding: const EdgeInsets.only(right: 12),
                      child: widget.prefixIcon,
                    )
                  : null,
              prefixIconConstraints: const BoxConstraints(minWidth: 24, minHeight: 24),
              suffixIcon: widget.suffixIcon,
              contentPadding: const EdgeInsets.symmetric(vertical: 14),
            ),
          ),
        ),
        if (_errorText != null && _errorText!.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.only(left: 8, top: 6),
            child: Text(
              _errorText!,
              style: TextStyle(
                color: neuTheme.dangerColor,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ],
    );
  }
}
