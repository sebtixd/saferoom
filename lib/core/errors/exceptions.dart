/// Base exception class for the application
class AppException implements Exception {
  final String message;
  final String? code;

  const AppException({required this.message, this.code});

  @override
  String toString() => 'AppException: $message (code: $code)';
}

/// Server exception for API errors
class ServerException extends AppException {
  const ServerException({required super.message, super.code});
}

/// Cache exception for local storage errors
class CacheException extends AppException {
  const CacheException({required super.message, super.code});
}

/// Authentication exception
class AuthException extends AppException {
  const AuthException({required super.message, super.code});
}

/// Network exception for connectivity issues
class NetworkException extends AppException {
  const NetworkException({required super.message, super.code});
}

/// AI Service exception
class AIServiceException extends AppException {
  const AIServiceException({required super.message, super.code});
}

/// Validation exception for input errors
class ValidationException extends AppException {
  const ValidationException({required super.message, super.code});
}
