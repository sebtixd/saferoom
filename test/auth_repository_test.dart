import 'package:flutter_test/flutter_test.dart';

import 'package:safe_room/core/errors/exceptions.dart';
import 'package:safe_room/core/errors/failures.dart';
import 'package:safe_room/data/models/auth_session.dart';
import 'package:safe_room/data/repositories/auth_repository_impl.dart';
import 'helpers/fakes.dart';

void main() {
  late FakeAuthApi api;
  late FakeTokenStorage tokens;
  late FakeLocalStorage local;
  late AuthRepositoryImpl repository;

  setUp(() {
    api = FakeAuthApi()..session = testSession();
    tokens = FakeTokenStorage();
    local = FakeLocalStorage();
    repository = AuthRepositoryImpl(api, tokens, local);
  });

  test('login stores tokens and login flags', () async {
    final result = await repository.login(email: 'user@example.com', password: 'password123');

    expect(result.isRight(), true);
    result.fold(
      (failure) => fail('Unexpected failure: $failure'),
      (user) => expect(user.id, 'user-1'),
    );
    expect(tokens.accessToken, 'access-1');
    expect(tokens.refreshToken, 'refresh-1');
    expect(await local.getString('user_id'), 'user-1');
    expect(await local.getBool('is_logged_in'), true);
  });

  test('login maps API errors to AuthFailure', () async {
    api.signInError = const AuthException(
      message: 'Invalid email or password',
      code: 'invalid_credentials',
    );

    final result = await repository.login(email: 'user@example.com', password: 'wrong');

    expect(result.isLeft(), true);
    result.fold(
      (failure) {
        expect(failure, isA<AuthFailure>());
        expect(failure.message, 'Invalid email or password');
      },
      (_) => fail('Expected a failure'),
    );
  });

  test('logout revokes the refresh token and clears local session', () async {
    await _seedSession(tokens, local);

    final result = await repository.logout();

    expect(result.isRight(), true);
    expect(api.signOutCalled, true);
    expect(api.revokedRefreshToken, 'refresh-1');
    expect(tokens.accessToken, isNull);
    expect(tokens.refreshToken, isNull);
    expect(await local.getBool('is_logged_in'), false);
  });

  test('getCurrentUser returns the cached user when the access token is valid', () async {
    await _seedSession(tokens, local);
    api.currentUser = testUser();

    final result = await repository.getCurrentUser();

    expect(result.isRight(), true);
    result.fold(
      (failure) => fail('Unexpected failure: $failure'),
      (user) => expect(user?.email, 'user@example.com'),
    );
    expect(api.refreshCount, 0);
  });

  test('getCurrentUser refreshes an expired access token and persists new tokens', () async {
    await _seedSession(tokens, local);
    api.currentUserError = const AuthException(
      message: 'Access token has expired',
      code: 'token_expired',
    );
    api.refreshedSession = AuthSession(
      user: testUser(),
      accessToken: 'access-2',
      refreshToken: 'refresh-2',
      expiresIn: 900,
    );

    final result = await repository.getCurrentUser();

    expect(result.isRight(), true);
    expect(api.refreshCount, 1);
    expect(tokens.accessToken, 'access-2');
    expect(tokens.refreshToken, 'refresh-2');
  });

  test('getCurrentUser returns null and clears storage when refresh fails', () async {
    await _seedSession(tokens, local);
    tokens.accessToken = null;
    api.refreshError = const AuthException(
      message: 'Refresh token is invalid or expired',
      code: 'invalid_refresh_token',
    );

    final result = await repository.getCurrentUser();

    expect(result.isLeft(), true);
    expect(tokens.accessToken, isNull);
    expect(tokens.clearCount, 1);
  });

  test('isLoggedIn reflects stored tokens', () async {
    expect(await repository.isLoggedIn(), false);
    tokens.accessToken = 'access-1';
    expect(await repository.isLoggedIn(), true);
    tokens.accessToken = null;
    tokens.refreshToken = 'refresh-1';
    expect(await repository.isLoggedIn(), true);
  });
}

Future<void> _seedSession(FakeTokenStorage tokens, FakeLocalStorage local) async {
  await tokens.saveTokens(accessToken: 'access-1', refreshToken: 'refresh-1');
  await local.saveString('user_id', 'user-1');
  await local.saveBool('is_logged_in', true);
}
