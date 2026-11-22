import 'package:dartz/dartz.dart';

import '../../core/errors/exceptions.dart';
import '../../core/errors/failures.dart';
import '../../domain/entities/user.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/local/local_storage_service.dart';
import '../datasources/local/token_storage.dart';
import '../datasources/remote/auth_api_service.dart';
import '../models/auth_session.dart';

/// Authentication backed by the SafeRoom HTTP API.
///
/// Tokens are stored in platform-secure storage; the user id/login flags are
/// mirrored in [LocalStorageService] for backwards compatibility.
class AuthRepositoryImpl implements AuthRepository {
  final AuthApiService _api;
  final TokenStorage _tokenStorage;
  final LocalStorageService _localStorage;

  AuthRepositoryImpl(this._api, this._tokenStorage, this._localStorage);

  @override
  Future<Either<Failure, User>> login({
    required String email,
    required String password,
  }) async {
    try {
      final session = await _api.signIn(email: email, password: password);
      await _persistSession(session);
      return Right(session.user);
    } on AppException catch (e) {
      return Left(_toFailure(e));
    }
  }

  @override
  Future<Either<Failure, User>> register({
    required String email,
    required String password,
  }) async {
    try {
      final session = await _api.register(email: email, password: password);
      await _persistSession(session);
      return Right(session.user);
    } on AppException catch (e) {
      return Left(_toFailure(e));
    }
  }

  @override
  Future<Either<Failure, void>> logout() async {
    final refreshToken = await _tokenStorage.readRefreshToken();
    try {
      if (refreshToken != null) {
        await _api.signOut(refreshToken: refreshToken);
      }
    } on AppException {
      // A server error must not prevent the user from signing out locally.
    } finally {
      await _clearSession();
    }
    return const Right(null);
  }

  @override
  Future<Either<Failure, User?>> getCurrentUser() async {
    final accessToken = await _tokenStorage.readAccessToken();
    if (accessToken != null) {
      try {
        final user = await _api.getCurrentUser(accessToken: accessToken);
        await _cacheUser(user);
        return Right(user);
      } on AuthException catch (e) {
        if (e.code != 'invalid_token' && e.code != 'token_expired') {
          return Left(AuthFailure(message: e.message, code: e.code));
        }
        return _restoreFromRefreshToken();
      } on AppException catch (e) {
        return Left(_toFailure(e));
      }
    }
    return _restoreFromRefreshToken();
  }

  @override
  Future<bool> isLoggedIn() async {
    final access = await _tokenStorage.readAccessToken();
    if (access != null) return true;
    final refresh = await _tokenStorage.readRefreshToken();
    return refresh != null;
  }

  @override
  Future<Either<Failure, void>> resetPassword(String email) async {
    try {
      await _api.requestPasswordReset(email);
      return const Right(null);
    } on AppException catch (e) {
      return Left(_toFailure(e));
    }
  }

  Future<Either<Failure, User?>> _restoreFromRefreshToken() async {
    final refreshToken = await _tokenStorage.readRefreshToken();
    if (refreshToken == null) {
      await _clearSession();
      return const Right(null);
    }
    try {
      final session = await _api.refresh(refreshToken: refreshToken);
      await _persistSession(session);
      return Right(session.user);
    } on AppException catch (e) {
      await _clearSession();
      return Left(_toFailure(e));
    }
  }

  Future<void> _persistSession(AuthSession session) async {
    await _tokenStorage.saveTokens(
      accessToken: session.accessToken,
      refreshToken: session.refreshToken,
    );
    await _cacheUser(session.user);
  }

  Future<void> _cacheUser(User user) async {
    await _localStorage.saveString('user_id', user.id);
    await _localStorage.saveBool('is_logged_in', true);
  }

  Future<void> _clearSession() async {
    await _tokenStorage.clear();
    await _localStorage.remove('user_id');
    await _localStorage.saveBool('is_logged_in', false);
    await _localStorage.remove('is_anonymous');
  }

  Failure _toFailure(AppException exception) {
    if (exception is NetworkException) {
      return NetworkFailure(message: exception.message, code: exception.code);
    }
    if (exception is ValidationException) {
      return ValidationFailure(message: exception.message, code: exception.code);
    }
    if (exception is AuthException) {
      return AuthFailure(message: exception.message, code: exception.code);
    }
    if (exception is ServerException) {
      return ServerFailure(message: exception.message, code: exception.code);
    }
    return UnknownFailure(message: exception.message, code: exception.code);
  }
}
