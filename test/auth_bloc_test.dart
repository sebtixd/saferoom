import 'package:flutter_test/flutter_test.dart';

import 'package:safe_room/data/repositories/auth_repository_impl.dart';
import 'package:safe_room/domain/usecases/auth/get_current_user_usecase.dart';
import 'package:safe_room/domain/usecases/auth/login_usecase.dart';
import 'package:safe_room/domain/usecases/auth/logout_usecase.dart';
import 'package:safe_room/domain/usecases/auth/register_usecase.dart';
import 'package:safe_room/presentation/blocs/auth/auth_bloc.dart';
import 'package:safe_room/presentation/blocs/auth/auth_event.dart';
import 'package:safe_room/presentation/blocs/auth/auth_state.dart';
import 'helpers/fakes.dart';

void main() {
  late FakeAuthApi api;
  late FakeTokenStorage tokens;
  late FakeLocalStorage local;
  late AuthBloc bloc;

  setUp(() {
    api = FakeAuthApi()..session = testSession();
    tokens = FakeTokenStorage();
    local = FakeLocalStorage();
    final repository = AuthRepositoryImpl(api, tokens, local);
    bloc = AuthBloc(
      loginUseCase: LoginUseCase(repository),
      registerUseCase: RegisterUseCase(repository),
      logoutUseCase: LogoutUseCase(repository),
      getCurrentUserUseCase: GetCurrentUserUseCase(repository),
    );
  });

  tearDown(() async {
    await bloc.close();
  });

  test('AuthCheckRequested restores an existing session', () async {
    await tokens.saveTokens(accessToken: 'access-1', refreshToken: 'refresh-1');
    api.currentUser = testUser();

    final stateFuture = bloc.stream.firstWhere(
      (state) => state is AuthAuthenticated || state is AuthUnauthenticated,
    );
    bloc.add(const AuthCheckRequested());
    final state = await stateFuture.timeout(const Duration(seconds: 2));

    expect(state, isA<AuthAuthenticated>());
    final authenticated = state as AuthAuthenticated;
    expect(authenticated.user.id, 'user-1');
    expect(authenticated.needsOnboarding, true);
  });

  test('AuthCheckRequested emits unauthenticated when there is no session', () async {
    final stateFuture = bloc.stream.firstWhere(
      (state) => state is AuthAuthenticated || state is AuthUnauthenticated,
    );
    bloc.add(const AuthCheckRequested());
    final state = await stateFuture.timeout(const Duration(seconds: 2));

    expect(state, isA<AuthUnauthenticated>());
  });
}
