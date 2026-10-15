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
  static const _keyServerUrl = 'atlas_server_url';

  Future<void> saveTokens({required String accessToken, required String refreshToken}) async {
    _memoryFallback[_keyAccessToken] = accessToken;
    _memoryFallback[_keyRefreshToken] = refreshToken;
    try {
      await _storage.write(key: _keyAccessToken, value: accessToken);
      await _storage.write(key: _keyRefreshToken, value: refreshToken);
    } catch (_) {}
  }

  Future<String?> getAccessToken() async {
    if (_memoryFallback.containsKey(_keyAccessToken)) {
      return _memoryFallback[_keyAccessToken];
    }
    try {
      final token = await _storage.read(key: _keyAccessToken);
      if (token != null) _memoryFallback[_keyAccessToken] = token;
      return token;
    } catch (_) {
      return null;
    }
  }

  Future<String?> getRefreshToken() async {
    if (_memoryFallback.containsKey(_keyRefreshToken)) {
      return _memoryFallback[_keyRefreshToken];
    }
    try {
      final token = await _storage.read(key: _keyRefreshToken);
      if (token != null) _memoryFallback[_keyRefreshToken] = token;
      return token;
    } catch (_) {
      return null;
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
    if (_memoryFallback.containsKey(_keyUserRole)) {
      return _memoryFallback[_keyUserRole];
    }
    try {
      final role = await _storage.read(key: _keyUserRole);
      if (role != null) _memoryFallback[_keyUserRole] = role;
      return role;
    } catch (_) {
      return null;
    }
  }

  Future<String?> getUserId() async {
    if (_memoryFallback.containsKey(_keyUserId)) {
      return _memoryFallback[_keyUserId];
    }
    try {
      final uid = await _storage.read(key: _keyUserId);
      if (uid != null) _memoryFallback[_keyUserId] = uid;
      return uid;
    } catch (_) {
      return null;
    }
  }

  Future<void> saveThemeMode(String mode) async {
    _memoryFallback[_keyThemeMode] = mode;
    try {
      await _storage.write(key: _keyThemeMode, value: mode);
    } catch (_) {}
  }

  Future<String?> getThemeMode() async {
    if (_memoryFallback.containsKey(_keyThemeMode)) {
      return _memoryFallback[_keyThemeMode];
    }
    try {
      final mode = await _storage.read(key: _keyThemeMode);
      if (mode != null) _memoryFallback[_keyThemeMode] = mode;
      return mode;
    } catch (_) {
      return null;
    }
  }

  Future<void> saveServerUrl(String url) async {
    _memoryFallback[_keyServerUrl] = url;
    try {
      await _storage.write(key: _keyServerUrl, value: url);
    } catch (_) {}
  }

  Future<String?> getServerUrl() async {
    if (_memoryFallback.containsKey(_keyServerUrl)) {
      return _memoryFallback[_keyServerUrl];
    }
    try {
      final url = await _storage.read(key: _keyServerUrl);
      if (url != null) _memoryFallback[_keyServerUrl] = url;
      return url;
    } catch (_) {
      return null;
    }
  }

  Future<void> clearAuth() async {
    _memoryFallback.remove(_keyAccessToken);
    _memoryFallback.remove(_keyRefreshToken);
    _memoryFallback.remove(_keyUserId);
    _memoryFallback.remove(_keyUserRole);
    try {
      await _storage.delete(key: _keyAccessToken);
      await _storage.delete(key: _keyRefreshToken);
      await _storage.delete(key: _keyUserId);
      await _storage.delete(key: _keyUserRole);
    } catch (_) {}
  }
}

