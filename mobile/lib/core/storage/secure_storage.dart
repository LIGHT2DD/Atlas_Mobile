import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../shared/models/user_model.dart';

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
  static const _keyCachedUser = 'atlas_cached_user';
  static const _keyOfflineAccounts = 'atlas_offline_accounts';

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

  Future<void> saveCachedUser(UserModel user) async {
    final jsonStr = jsonEncode(user.toJson());
    _memoryFallback[_keyCachedUser] = jsonStr;
    try {
      await _storage.write(key: _keyCachedUser, value: jsonStr);
    } catch (_) {}
  }

  Future<UserModel?> getCachedUser() async {
    String? raw = _memoryFallback[_keyCachedUser];
    if (raw == null) {
      try {
        raw = await _storage.read(key: _keyCachedUser);
        if (raw != null) _memoryFallback[_keyCachedUser] = raw;
      } catch (_) {}
    }
    if (raw != null && raw.isNotEmpty) {
      try {
        final decoded = jsonDecode(raw) as Map<String, dynamic>;
        return UserModel.fromJson(decoded);
      } catch (_) {}
    }
    return null;
  }

  Future<void> saveOfflineAccount(Map<String, dynamic> account) async {
    final accounts = await getOfflineAccounts();
    final cleanEmail = (account['email'] as String? ?? '').trim().toLowerCase();
    accounts.removeWhere((a) => (a['email'] as String? ?? '').trim().toLowerCase() == cleanEmail);
    accounts.add(account);
    final jsonStr = jsonEncode(accounts);
    _memoryFallback[_keyOfflineAccounts] = jsonStr;
    try {
      await _storage.write(key: _keyOfflineAccounts, value: jsonStr);
    } catch (_) {}
  }

  Future<List<Map<String, dynamic>>> getOfflineAccounts() async {
    String? raw = _memoryFallback[_keyOfflineAccounts];
    if (raw == null) {
      try {
        raw = await _storage.read(key: _keyOfflineAccounts);
        if (raw != null) _memoryFallback[_keyOfflineAccounts] = raw;
      } catch (_) {}
    }
    if (raw != null && raw.isNotEmpty) {
      try {
        final decoded = jsonDecode(raw);
        if (decoded is List) {
          return decoded.map((e) => Map<String, dynamic>.from(e as Map)).toList();
        }
      } catch (_) {}
    }
    return [];
  }

  Future<Map<String, dynamic>?> findOfflineAccount(String email) async {
    final accounts = await getOfflineAccounts();
    final cleanEmail = email.trim().toLowerCase();
    for (final acc in accounts) {
      if ((acc['email'] as String? ?? '').trim().toLowerCase() == cleanEmail) {
        return acc;
      }
    }
    return null;
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

  Future<void> saveCachedPayload(String key, String jsonString) async {
    final storageKey = 'cache_$key';
    _memoryFallback[storageKey] = jsonString;
    try {
      await _storage.write(key: storageKey, value: jsonString);
    } catch (_) {}
  }

  Future<String?> getCachedPayload(String key) async {
    final storageKey = 'cache_$key';
    if (_memoryFallback.containsKey(storageKey)) {
      return _memoryFallback[storageKey];
    }
    try {
      final data = await _storage.read(key: storageKey);
      if (data != null) _memoryFallback[storageKey] = data;
      return data;
    } catch (_) {
      return null;
    }
  }

  Future<void> clearCachedPayload(String key) async {
    final storageKey = 'cache_$key';
    _memoryFallback.remove(storageKey);
    try {
      await _storage.delete(key: storageKey);
    } catch (_) {}
  }

  Future<void> clearAuth() async {
    _memoryFallback.remove(_keyAccessToken);
    _memoryFallback.remove(_keyRefreshToken);
    _memoryFallback.remove(_keyUserId);
    _memoryFallback.remove(_keyUserRole);
    _memoryFallback.remove(_keyCachedUser);
    try {
      await _storage.delete(key: _keyAccessToken);
      await _storage.delete(key: _keyRefreshToken);
      await _storage.delete(key: _keyUserId);
      await _storage.delete(key: _keyUserRole);
      await _storage.delete(key: _keyCachedUser);
    } catch (_) {}
  }
}

