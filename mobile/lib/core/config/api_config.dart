import 'package:flutter/foundation.dart';

class ApiConfig {
  /// Compile-time configured base URL passed via:
  /// `flutter run --dart-define=API_BASE_URL=https://your-cloud-api.com`
  static const String _envBaseUrl = String.fromEnvironment('API_BASE_URL');

  /// Default cloud production URL (e.g., Render, Railway, Google Cloud Run).
  /// Used automatically in release builds or when pointing to a live backend.
  static const String defaultProductionUrl = 'https://atlas-api.onrender.com';

  /// Optional runtime override (useful for settings page or unit/integration testing).
  static String? _overrideBaseUrl;

  /// Programmatically set or reset a custom runtime base URL.
  static void setCustomBaseUrl(String? url) {
    _overrideBaseUrl = url;
  }

  /// Resolved backend base URL.
  /// Priority:
  /// 1. Explicit runtime override (if configured via [setCustomBaseUrl])
  /// 2. Compile-time `--dart-define=API_BASE_URL=...`
  /// 3. Release build (`kReleaseMode`) -> [defaultProductionUrl]
  /// 4. Local development fallbacks:
  ///    - Android emulator -> http://10.0.2.2:8000
  ///    - Chrome web & desktop / iOS simulator -> http://localhost:8000
  static String get baseUrl {
    if (_overrideBaseUrl != null && _overrideBaseUrl!.isNotEmpty) {
      return _overrideBaseUrl!;
    }

    if (_envBaseUrl.isNotEmpty) {
      return _envBaseUrl;
    }

    if (kReleaseMode) {
      return defaultProductionUrl;
    }

    if (kIsWeb) return 'http://localhost:8000';
    if (defaultTargetPlatform == TargetPlatform.android) {
      return 'http://10.0.2.2:8000';
    }
    return 'http://localhost:8000';
  }

  static const String apiMobileV1 = '/api/mobile/v1';

  static const Duration connectTimeout = Duration(seconds: 15);
  static const Duration receiveTimeout = Duration(seconds: 15);
  static const Duration sendTimeout = Duration(seconds: 30);
}

