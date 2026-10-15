import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/neumorphic_theme.dart';
import 'neu_button.dart';

/// Seamless Neumorphic AppBar that blends directly into the surface
class NeuAppBar extends ConsumerWidget implements PreferredSizeWidget {
  final String title;
  final Widget? leading;
  final List<Widget>? actions;
  final bool showThemeToggle;
  final bool automaticallyImplyLeading;
  final double height;

  const NeuAppBar({
    super.key,
    required this.title,
    this.leading,
    this.actions,
    this.showThemeToggle = true,
    this.automaticallyImplyLeading = true,
    this.height = 70.0,
  });

  @override
  Size get preferredSize => Size.fromHeight(height);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final neuTheme = context.neuTheme;
    final currentThemeMode = ref.watch(themeModeProvider);
    final isDark = currentThemeMode == ThemeMode.dark;

    Widget? leadingWidget = leading;
    if (leadingWidget == null && automaticallyImplyLeading) {
      final ScaffoldState? scaffold = Scaffold.maybeOf(context);
      final hasDrawer = scaffold?.hasDrawer ?? false;
      final canPop = Navigator.of(context).canPop() || GoRouter.of(context).canPop();

      if (hasDrawer) {
        leadingWidget = NeuIconButton(
          icon: TablerIcons.menu_2,
          tooltip: 'Navigation Menu',
          onPressed: () => Scaffold.of(context).openDrawer(),
        );
      } else if (canPop) {
        leadingWidget = NeuIconButton(
          icon: TablerIcons.arrow_left,
          tooltip: 'Go Back',
          onPressed: () {
            if (GoRouter.of(context).canPop()) {
              context.pop();
            } else {
              Navigator.of(context).maybePop();
            }
          },
        );
      }
    }

    final actionWidgets = <Widget>[
      ...?actions,
      if (showThemeToggle) ...[
        Padding(
          padding: const EdgeInsets.only(right: 12.0),
          child: NeuIconButton(
            icon: isDark ? TablerIcons.sun : TablerIcons.moon,
            tooltip: isDark ? 'Switch to Light Mode' : 'Switch to Dark Mode',
            iconColor: isDark ? const Color(0xFFF6E05E) : neuTheme.accentColor,
            onPressed: () {
              ref.read(themeModeProvider.notifier).toggleTheme();
            },
          ),
        ),
      ],
    ];

    return SafeArea(
      bottom: false,
      child: Container(
        height: height,
        color: neuTheme.baseColor,
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        child: Row(
          children: [
            if (leadingWidget != null) ...[
              leadingWidget,
              const SizedBox(width: 14),
            ],
            Expanded(
              child: Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: neuTheme.textPrimary,
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.2,
                ),
              ),
            ),
            ...actionWidgets,
          ],
        ),
      ),
    );
  }
}
