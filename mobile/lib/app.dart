import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/routing/app_router.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/neumorphic_theme.dart';

class AtlasApp extends ConsumerWidget {
  const AtlasApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);
    final themeMode = ref.watch(themeModeProvider);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      precacheImage(const AssetImage('asset/icon/play_store_512.png'), context).catchError((_) {});
      precacheImage(const AssetImage('assets/icon/play_store_512.png'), context).catchError((_) {});
    });

    return MaterialApp.router(
      title: 'ATLAS - Academic Thesis Lifecycle & Assessment Suite',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.neumorphicLightTheme,
      darkTheme: AppTheme.neumorphicDarkTheme,
      themeMode: themeMode,
      routerConfig: router,
    );
  }
}
