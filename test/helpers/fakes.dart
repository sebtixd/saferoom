import 'package:safe_room/core/errors/exceptions.dart';
import 'package:safe_room/data/datasources/local/local_storage_service.dart';
import 'package:safe_room/data/datasources/local/token_storage.dart';
import 'package:safe_room/data/datasources/remote/auth_api_service.dart';
import 'package:safe_room/data/models/auth_session.dart';
import 'package:safe_room/domain/entities/emotional_profile.dart';
import 'package:safe_room/domain/entities/user.dart';

class FakeLocalStorage implements LocalStorageService {
  final Map<String, Object> _values = {};

  @override
  Future<void> saveString(String key, String value) async => _values[key] = value;

  @override
  Future<String?> getString(String key) async => _values[key] as String?;

  @override
  Future<void> saveBool(String key, bool value) async => _values[key] = value;

  @override
  Future<bool?> getBool(String key) async => _values[key] as bool?;

  @override
  Future<void> saveInt(String key, int value) async => _values[key] = value;

  @override
  Future<int?> getInt(String key) async => _values[key] as int?;

  @override
  Future<void> saveJson(String key, Map<String, dynamic> value) async =>
      _values[key] = value;

  @override
  Future<Map<String, dynamic>?> getJson(String key) async =>
      _values[key] as Map<String, dynamic>?;

  @override
  Future<void> remove(String key) async => _values.remove(key);

  @override
  Future<void> clear() async => _values.clear();

  @override
  Future<List<Map<String, dynamic>>> getRoomDecor(String userId) async {
    final raw = _values['room_decor_$userId'];
    if (raw is! Map<String, dynamic>) return const [];
    final objects = raw['objects'];
    if (objects is! List) return const [];
    return objects
        .whereType<Map>()
        .map((entry) => Map<String, dynamic>.from(entry))
        .toList(growable: false);
  }

  @override
  Future<void> saveRoomDecor(
    String userId,
    List<Map<String, dynamic>> objects,
  ) async {
    _values['room_decor_$userId'] = {'objects': objects};
  }
}

class FakeTokenStorage implements TokenStorage {
  String? accessToken;
  String? refreshToken;
  int clearCount = 0;

  @override
  Future<String?> readAccessToken() async => accessToken;

  @override
  Future<String?> readRefreshToken() async => refreshToken;

  @override
  Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
  }) async {
    this.accessToken = accessToken;
    this.refreshToken = refreshToken;
  }

  @override
  Future<void> clear() async {
    accessToken = null;
    refreshToken = null;
    clearCount++;
  }
}

class FakeAuthApi extends AuthApiService {
  AuthSession? session;
  AuthSession? refreshedSession;
  User? currentUser;
  AppException? signInError;
  AppException? currentUserError;
  AppException? refreshError;
  bool signOutCalled = false;
  String? revokedRefreshToken;
  int refreshCount = 0;

  @override
  Future<AuthSession> signIn({
    required String email,
    required String password,
  }) async {
    if (signInError != null) throw signInError!;
    return session!;
  }

  @override
  Future<AuthSession> register({
    required String email,
    required String password,
  }) async {
    if (signInError != null) throw signInError!;
    return session!;
  }

  @override
  Future<void> signOut({required String refreshToken}) async {
    signOutCalled = true;
    revokedRefreshToken = refreshToken;
  }

  @override
  Future<User> getCurrentUser({required String accessToken}) async {
    if (currentUserError != null) throw currentUserError!;
    return currentUser!;
  }

  @override
  Future<AuthSession> refresh({required String refreshToken}) async {
    refreshCount++;
    if (refreshError != null) throw refreshError!;
    return refreshedSession ?? session!;
  }
}

User testUser({EmotionalProfile? profile}) => UserModelStub(
      id: 'user-1',
      email: 'user@example.com',
      profile: profile,
    );

class UserModelStub extends User {
  UserModelStub({
    required super.id,
    required super.email,
    EmotionalProfile? profile,
  }) : super(
          isAnonymous: false,
          createdAt: DateTime.utc(2026),
          emotionalProfile: profile,
        );
}

AuthSession testSession({User? user}) => AuthSession(
      user: user ?? testUser(),
      accessToken: 'access-1',
      refreshToken: 'refresh-1',
      expiresIn: 900,
    );
