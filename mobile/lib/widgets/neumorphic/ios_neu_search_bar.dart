import 'package:flutter/material.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import '../../core/theme/ios_neu_theme.dart';

/// Minimalist iOS Neumorphic Stadium Search Bar
class IosNeuSearchBar extends StatefulWidget {
  final TextEditingController? controller;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final VoidCallback? onClear;
  final String hintText;
  final FocusNode? focusNode;
  final bool autoFocus;

  const IosNeuSearchBar({
    super.key,
    this.controller,
    this.onChanged,
    this.onSubmitted,
    this.onClear,
    this.hintText = 'Search...',
    this.focusNode,
    this.autoFocus = false,
  });

  @override
  State<IosNeuSearchBar> createState() => _IosNeuSearchBarState();
}

class _IosNeuSearchBarState extends State<IosNeuSearchBar> {
  late TextEditingController _controller;
  bool _hasText = false;

  @override
  void initState() {
    super.initState();
    _controller = widget.controller ?? TextEditingController();
    _hasText = _controller.text.isNotEmpty;
    _controller.addListener(_handleTextChange);
  }

  void _handleTextChange() {
    final has = _controller.text.isNotEmpty;
    if (has != _hasText) {
      setState(() => _hasText = has);
    }
  }

  @override
  void dispose() {
    if (widget.controller == null) {
      _controller.dispose();
    } else {
      _controller.removeListener(_handleTextChange);
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 52.0,
      decoration: BoxDecoration(
        color: IosNeuColors.canvas,
        borderRadius: BorderRadius.circular(30.0),
        boxShadow: IosNeuTheme.subtleShadows,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 18.0),
      alignment: Alignment.center,
      child: Row(
        children: [
          const Icon(
            TablerIcons.search,
            size: 20,
            color: IosNeuColors.textSecondary,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: _controller,
              focusNode: widget.focusNode,
              autofocus: widget.autoFocus,
              style: const TextStyle(
                color: IosNeuColors.textPrimary,
                fontSize: 15,
                fontWeight: FontWeight.w500,
              ),
              cursorColor: IosNeuColors.activePill,
              decoration: InputDecoration(
                hintText: widget.hintText,
                hintStyle: const TextStyle(
                  color: IosNeuColors.textSecondary,
                  fontSize: 15,
                  fontWeight: FontWeight.w400,
                ),
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.zero,
              ),
              onChanged: widget.onChanged,
              onSubmitted: widget.onSubmitted,
            ),
          ),
          if (_hasText) ...[
            GestureDetector(
              onTap: () {
                _controller.clear();
                widget.onChanged?.call('');
                widget.onClear?.call();
              },
              child: Container(
                width: 22,
                height: 22,
                decoration: const BoxDecoration(
                  color: IosNeuColors.inactiveBadge,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  TablerIcons.x,
                  size: 14,
                  color: IosNeuColors.textPrimary,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
