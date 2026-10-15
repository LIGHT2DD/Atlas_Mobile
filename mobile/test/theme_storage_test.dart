import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:atlas_mobile/core/storage/secure_storage.dart';
import 'package:atlas_mobile/core/theme/neumorphic_theme.dart';

void main() {
  group('ThemeMode and SecureStorage Tests', () {
    test('SecureStorageService saves and retrieves theme mode correctly', () async {
      final storage = SecureStorageService();
      expect(await storage.getThemeMode(), isNull);

      await storage.saveThemeMode('dark');
      expect(await storage.getThemeMode(), equals('dark'));

      await storage.saveThemeMode('light');
      expect(await storage.getThemeMode(), equals('light'));
    });

    test('ThemeModeNotifier toggles theme and writes to storage', () async {
      final storage = SecureStorageService();
      final notifier = ThemeModeNotifier(storage);

      expect(notifier.state, equals(ThemeMode.light));
      expect(notifier.isDarkMode, isFalse);

      notifier.toggleTheme();
      expect(notifier.state, equals(ThemeMode.dark));
      expect(notifier.isDarkMode, isTrue);
      expect(await storage.getThemeMode(), equals('dark'));

      notifier.toggleTheme();
      expect(notifier.state, equals(ThemeMode.light));
      expect(notifier.isDarkMode, isFalse);
      expect(await storage.getThemeMode(), equals('light'));
    });

    test('ThemeModeNotifier restores saved dark theme from storage on initialization', () async {
      final storage = SecureStorageService();
      await storage.saveThemeMode('dark');

      final notifier = ThemeModeNotifier(storage);
      // Allow async load to complete
      await Future<void>.delayed(const Duration(milliseconds: 50));

      expect(notifier.state, equals(ThemeMode.dark));
      expect(notifier.isDarkMode, isTrue);
    });
  });
}
