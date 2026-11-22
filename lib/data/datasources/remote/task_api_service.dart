import '../local/token_storage.dart';
import 'api_client.dart';
import 'auth_api_service.dart';
import '../../../core/errors/exceptions.dart';
import '../../models/daily_task_model.dart';
import '../../../domain/entities/daily_task.dart';

/// HTTP client for the SQLite-backed daily task endpoints.
class TaskApiService {
  final ApiClient _api;
  final TokenStorage _tokenStorage;
  final AuthApiService _authApi;

  TaskApiService(this._api, this._tokenStorage, this._authApi);

  Future<DailyTask?> getDailyTasks({
    required String userId,
    required DateTime date,
  }) async {
    final dateStr = date.toIso8601String().substring(0, 10);
    final query =
        '?user_id=${Uri.encodeQueryComponent(userId)}&date=${Uri.encodeQueryComponent(dateStr)}';
    final json = await _sendWithAuth('/api/daily-tasks$query', 'GET');
    final raw = json['dailyTask'];
    if (raw == null) return null;
    return DailyTaskModel.fromJson(raw as Map<String, dynamic>);
  }

  Future<DailyTask> getDailyTaskById(String id) async {
    final json = await _sendWithAuth(
      '/api/daily-tasks/${Uri.encodeComponent(id)}',
      'GET',
    );
    return DailyTaskModel.fromJson(json['dailyTask'] as Map<String, dynamic>);
  }

  Future<DailyTask> saveDailyTasks(DailyTask dailyTask) async {
    final json = await _sendWithAuth(
      '/api/daily-tasks',
      'POST',
      body: DailyTaskModel.fromEntity(dailyTask).toJson(),
    );
    return DailyTaskModel.fromJson(json['dailyTask'] as Map<String, dynamic>);
  }

  Future<DailyTask> updateDailyTasks(DailyTask dailyTask) async {
    final tasks = dailyTask.tasks
        .map((task) => TaskItemModel.fromEntity(task).toJson())
        .toList();
    final json = await _sendWithAuth(
      '/api/daily-tasks/${Uri.encodeComponent(dailyTask.id)}',
      'PUT',
      body: {'tasks': tasks},
    );
    return DailyTaskModel.fromJson(json['dailyTask'] as Map<String, dynamic>);
  }

  /// Sends an authenticated request, transparently rotating the access token
  /// with the stored refresh token if it expired mid-session.
  Future<Map<String, dynamic>> _sendWithAuth(
    String path,
    String method, {
    Map<String, dynamic>? body,
  }) async {
    final token = await _accessToken();
    try {
      return await _api.send(
        path,
        method,
        accessToken: token,
        body: body,
      );
    } on AuthException catch (e) {
      if (e.code != 'invalid_token' && e.code != 'token_expired') rethrow;
      final refreshToken = await _tokenStorage.readRefreshToken();
      if (refreshToken == null || refreshToken.isEmpty) rethrow;

      final session = await _authApi.refresh(refreshToken: refreshToken);
      await _tokenStorage.saveTokens(
        accessToken: session.accessToken,
        refreshToken: session.refreshToken,
      );
      return _api.send(
        path,
        method,
        accessToken: session.accessToken,
        body: body,
      );
    }
  }

  Future<String> _accessToken() async {
    final token = await _tokenStorage.readAccessToken();
    if (token == null || token.isEmpty) {
      throw const AuthException(message: 'Not authenticated', code: 'invalid_token');
    }
    return token;
  }
}
