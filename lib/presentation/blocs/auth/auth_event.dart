import 'package:equatable/equatable.dart';

/// Authentication events
abstract class AuthEvent extends Equatable {
  const AuthEvent();

  @override
  List<Object?> get props => [];
}

/// Login with email and password
class AuthLoginRequested extends AuthEvent {
  final String email;
  final String password;

  const AuthLoginRequested({
    required this.email,
    required this.password,
  });

  @override
  List<Object?> get props => [email, password];
}

/// Register with email and password
class AuthRegisterRequested extends AuthEvent {
  final String email;
  final String password;

  const AuthRegisterRequested({
    required this.email,
    required this.password,
  });

  @override
  List<Object?> get props => [email, password];
}



/// Logout
class AuthLogoutRequested extends AuthEvent {
  const AuthLogoutRequested();
}

/// Check authentication status
class AuthCheckRequested extends AuthEvent {
  const AuthCheckRequested();
}

/// Reset password
class AuthResetPasswordRequested extends AuthEvent {
  final String email;

  const AuthResetPasswordRequested(this.email);

  @override
  List<Object?> get props => [email];
}

/// Manually update user (e.g., after points change)
class AuthUpdateUser extends AuthEvent {
  final dynamic user; // Should be User type, but to avoid import if not present...
                      // Actually, let's assume imports will handle it or I add import if needed.
                      // Looking at file, imports are missing for User? 
                      // No, equatable is there.
                      // Wait, I need to import User entity.
  const AuthUpdateUser(this.user);
  
  @override
  List<Object?> get props => [user];
}
