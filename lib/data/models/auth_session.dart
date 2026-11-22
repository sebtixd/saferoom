import '../../domain/entities/user.dart';
import 'user_model.dart';

/// Token pair plus the authenticated user returned by the auth API.
class AuthSession {
  final User user;
  final String accessToken;
  final String refreshToken;
  final int expiresIn;

  const AuthSession({
    required this.user,
    required this.accessToken,
    required this.refreshToken,
    required this.expiresIn,
  });

  factory AuthSession.fromJson(Map<String, dynamic> json) {
    return AuthSession(
      user: UserModel.fromJson(json['user'] as Map<String, dynamic>),
      accessToken: json['accessToken'] as String,
      refreshToken: json['refreshToken'] as String,
      expiresIn: (json['expiresIn'] as num?)?.toInt() ?? 900,
    );
  }
}
