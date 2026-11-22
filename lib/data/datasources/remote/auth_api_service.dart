import 'api_client.dart';
import '../../../domain/entities/emotional_profile.dart';
import '../../../domain/entities/user.dart';
import '../../models/auth_session.dart';
import '../../models/user_model.dart';

/// HTTP client for the SafeRoom authentication backend.
class AuthApiService {
  final ApiClient _api;

  AuthApiService([ApiClient? client]) : _api = client ?? ApiClient();

  Future<AuthSession> register({
    required String email,
    required String password,
  }) async {
    final json = await _api.send('/api/auth/register', 'POST', body: {
      'email': email,
      'password': password,
    });
    return AuthSession.fromJson(json);
  }

  Future<AuthSession> signIn({
    required String email,
    required String password,
  }) async {
    final json = await _api.send('/api/auth/login', 'POST', body: {
      'email': email,
      'password': password,
    });
    return AuthSession.fromJson(json);
  }

  Future<void> signOut({required String refreshToken}) async {
    await _api.send('/api/auth/logout', 'POST', body: {
      'refreshToken': refreshToken,
    });
  }

  Future<AuthSession> refresh({required String refreshToken}) async {
    final json = await _api.send('/api/auth/refresh', 'POST', body: {
      'refreshToken': refreshToken,
    });
    return AuthSession.fromJson(json);
  }

  Future<User> getCurrentUser({required String accessToken}) async {
    final json = await _api.send('/api/auth/me', 'GET', accessToken: accessToken);
    return UserModel.fromJson(json['user'] as Map<String, dynamic>);
  }

  Future<User> getUser({required String id, required String accessToken}) async {
    final json = await _api.send('/api/users/$id', 'GET', accessToken: accessToken);
    return UserModel.fromJson(json['user'] as Map<String, dynamic>);
  }

  Future<User> updatePoints({
    required String id,
    required int points,
    required String accessToken,
  }) async {
    final json = await _api.send(
      '/api/me',
      'PATCH',
      accessToken: accessToken,
      body: {'points': points},
    );
    return UserModel.fromJson(json['user'] as Map<String, dynamic>);
  }

  Future<EmotionalProfile> saveEmotionalProfile({
    required EmotionalProfile profile,
    required String accessToken,
  }) async {
    final body = EmotionalProfileModel.fromEntity(profile).toJson();
    final json = await _api.send(
      '/api/me/emotional-profile',
      'PUT',
      accessToken: accessToken,
      body: body,
    );
    return EmotionalProfileModel.fromJson(
      json['emotionalProfile'] as Map<String, dynamic>,
    );
  }

  Future<void> requestPasswordReset(String email) async {
    await _api.send('/api/auth/forgot-password', 'POST', body: {'email': email});
  }

  Future<void> resetPassword({
    required String token,
    required String newPassword,
  }) async {
    await _api.send('/api/auth/reset-password', 'POST', body: {
      'token': token,
      'newPassword': newPassword,
    });
  }
}
