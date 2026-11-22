import 'package:equatable/equatable.dart';

/// Base failure class for error handling
abstract class Failure extends Equatable {
  final String message;
  final String? code;

  const Failure({required this.message, this.code});

  @override
  List<Object?> get props => [message, code];
}

/// Server failure for API errors
class ServerFailure extends Failure {
  const ServerFailure({required super.message, super.code});
}

/// Cache failure for local storage errors
class CacheFailure extends Failure {
  const CacheFailure({required super.message, super.code});
}

/// Authentication failure
class AuthFailure extends Failure {
  const AuthFailure({required super.message, super.code});
}

/// Network failure for connectivity issues
class NetworkFailure extends Failure {
  const NetworkFailure({required super.message, super.code});
}

/// AI Service failure
class AIServiceFailure extends Failure {
  const AIServiceFailure({required super.message, super.code});
}

/// Validation failure for input errors
class ValidationFailure extends Failure {
  const ValidationFailure({required super.message, super.code});
}

/// Unknown failure for unexpected errors
class UnknownFailure extends Failure {
  const UnknownFailure({super.message = 'An unexpected error occurred', super.code});
}
