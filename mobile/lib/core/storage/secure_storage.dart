import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

final secureStorageProvider = Provider<SecureStorageService>((ref) {
  return SecureStorageService();
});

class SecureStorageService {
  final FlutterSecureStorage _storage;
  final Map<String, String> _memoryFallback = {};

  SecureStorageService([FlutterSecureStorage? storage])
      : _storage = storage ?? const FlutterSecureStorage();

  static const _keyAccessToken = 'atlas_access_token';
  static const _keyRefreshToken = 'atlas_refresh_token';
  static const _keyUserId = 'atlas_user_id';
  static const _keyUserRole = 'atlas_user_role';
  static const _keyThemeMode = 'atlas_theme_mode';

  Future<void> saveTokens({required String accessToken, required String refreshToken}) async {
    _memoryFallback[_keyAccessToken] = accessToken;
    _memoryFallback[_keyRefreshToken] = refreshToken;
    try {
      await _storage.write(key: _keyAccessToken, value: accessToken);
      await _storage.write(key: _keyRefreshToken, value: refreshToken);
    } catch (_) {}
  }

  Future<String?> getAccessToken() async {
    try {
      return await _storage.read(key: _keyAccessToken) ?? _memoryFallback[_keyAccessToken];
    } catch (_) {
      return _memoryFallback[_keyAccessToken];
    }
  }

  Future<String?> getRefreshToken() async {
    try {
      return await _storage.read(key: _keyRefreshToken) ?? _memoryFallback[_keyRefreshToken];
    } catch (_) {
      return _memoryFallback[_keyRefreshToken];
    }
  }

  Future<void> saveUserMeta({required String userId, required String role}) async {
    _memoryFallback[_keyUserId] = userId;
    _memoryFallback[_keyUserRole] = role;
    try {
      await _storage.write(key: _keyUserId, value: userId);
      await _storage.write(key: _keyUserRole, value: role);
    } catch (_) {}
  }

  Future<String?> getUserRole() async {
    try {
      return await _storage.read(key: _keyUserRole) ?? _memoryFallback[_keyUserRole];
    } catch (_) {
      return _memoryFallback[_keyUserRole];
    }
  }

  Future<String?> getUserId() async {
    try {
      return await _storage.read(key: _keyUserId) ?? _memoryFallback[_keyUserId];
    } catch (_) {
      return _memoryFallback[_keyUserId];
    }
  }

  Future<void> saveThemeMode(String mode) async {
    _memoryFallback[_keyThemeMode] = mode;
    try {
      await _storage.write(key: _keyThemeMode, value: mode);
    } catch (_) {}
  }

  Future<String?> getThemeMode() async {
    try {
      return await _storage.read(key: _keyThemeMode) ?? _memoryFallback[_keyThemeMode];
    } catch (_) {
      return _memoryFallback[_keyThemeMode];
    }
  }

  Future<void> clearAuth() async {
    _memoryFallback.clear();
    try {
      await _storage.delete(key: _keyAccessToken);
      await _storage.delete(key: _keyRefreshToken);
      await _storage.delete(key: _keyUserId);
      await _storage.delete(key: _keyUserRole);
    } catch (_) {}
  }
}

