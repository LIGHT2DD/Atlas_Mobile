import 'package:flutter/foundation.dart';

class ApiConfig {
  /// Compile-time configured base URL passed via:
  /// `flutter run --dart-define=API_BASE_URL=https://your-cloud-api.com`
  static const String _envBaseUrl = String.fromEnvironment('API_BASE_URL');

  /// Local development host on physical Wi-Fi network
  static const String defaultLocalIp = 'http://192.168.0.105:8000';

  /// Optional cloud production URL
  static const String defaultProductionUrl = 'https://atlas-api.onrender.com';

  /// Optional runtime override (useful for settings page or unit/integration testing).
  static String? _overrideBaseUrl;

  /// Programmatically set or reset a custom runtime base URL.
  static void setCustomBaseUrl(String? url) {
    _overrideBaseUrl = url?.trim();
  }

  /// Resolved backend base URL.
  static String get baseUrl {
    if (_overrideBaseUrl != null && _overrideBaseUrl!.isNotEmpty) {
      return _overrideBaseUrl!;
    }

    if (_envBaseUrl.isNotEmpty) {
      return _envBaseUrl;
    }

    if (kIsWeb) return 'http://localhost:8000';

    if (defaultTargetPlatform == TargetPlatform.android) {
      return defaultLocalIp;
    }

    return 'http://localhost:8000';
  }

  static const String apiMobileV1 = '/api/mobile/v1';

  static const Duration connectTimeout = Duration(seconds: 5);
  static const Duration receiveTimeout = Duration(seconds: 8);
  static const Duration sendTimeout = Duration(seconds: 15);
}

