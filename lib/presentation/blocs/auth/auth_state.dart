import 'package:equatable/equatable.dart';
import '../../../domain/entities/user.dart';

/// Authentication states
abstract class AuthState extends Equatable {
  const AuthState();

  @override
  List<Object?> get props => [];
}

/// Initial state
class AuthInitial extends AuthState {
  const AuthInitial();
}

/// Loading state
class AuthLoading extends AuthState {
  const AuthLoading();
}

/// Authenticated state
class AuthAuthenticated extends AuthState {
  final User user;
  final bool needsOnboarding;

  const AuthAuthenticated({
    required this.user,
    this.needsOnboarding = false,
  });

  @override
  List<Object?> get props => [user, needsOnboarding];
}

/// Unauthenticated state
class AuthUnauthenticated extends AuthState {
  const AuthUnauthenticated();
}

/// Error state
class AuthError extends AuthState {
  final String message;

  const AuthError(this.message);

  @override
  List<Object?> get props => [message];
}

/// Password reset sent state
class AuthPasswordResetSent extends AuthState {
  const AuthPasswordResetSent();
}
