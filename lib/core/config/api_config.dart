/// Runtime configuration for external services.
///
/// Values can be overridden at build/run time with `--dart-define`, for example:
///
/// ```bash
/// flutter run -d web-server \
///   --dart-define=SAFEROOM_API_BASE_URL=http://192.168.1.20:3000
/// ```
class ApiConfig {
  ApiConfig._();

  /// Base URL of the SafeRoom authentication backend.
  static const String authBaseUrl = String.fromEnvironment(
    'SAFEROOM_API_BASE_URL',
    defaultValue: 'http://127.0.0.1:3000',
  );

  /// Google Gemini key. Can be overridden with `--dart-define=SAFEROOM_GEMINI_API_KEY=...`.
  static const String geminiApiKey = String.fromEnvironment(
    'SAFEROOM_GEMINI_API_KEY',
    defaultValue: 'AQ.Ab8RN6JJEoevFyObvTsmNRjFgnKtfMnYOSEKtjNP4PEH50UeUQ',
  );

  static const Duration connectTimeout = Duration(seconds: 10);
  static const Duration receiveTimeout = Duration(seconds: 15);
}
