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

    test('SecureStorageService saves and retrieves server URL correctly', () async {
      final storage = SecureStorageService();
      expect(await storage.getServerUrl(), isNull);

      await storage.saveServerUrl('http://192.168.1.100:8000');
      expect(await storage.getServerUrl(), equals('http://192.168.1.100:8000'));
    });

    test('SecureStorageService saves user meta and clears auth correctly', () async {
      final storage = SecureStorageService();
      await storage.saveTokens(accessToken: 'access-123', refreshToken: 'refresh-456');
      await storage.saveUserMeta(userId: 'u-1', role: 'student');

      expect(await storage.getAccessToken(), equals('access-123'));
      expect(await storage.getRefreshToken(), equals('refresh-456'));
      expect(await storage.getUserId(), equals('u-1'));
      expect(await storage.getUserRole(), equals('student'));

      await storage.clearAuth();
      expect(await storage.getAccessToken(), isNull);
      expect(await storage.getRefreshToken(), isNull);
      expect(await storage.getUserId(), isNull);
      expect(await storage.getUserRole(), isNull);
    });
  });
}
