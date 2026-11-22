// Live smoke test for the SafeRoom auth backend.
// Start the backend first: node backend/src/server.js
// Then run: dart run tool/verify_auth_api.dart
import 'dart:io';

import 'package:safe_room/data/datasources/remote/auth_api_service.dart';

Future<void> main() async {
  final api = AuthApiService();
  final email = 'smoke-${DateTime.now().millisecondsSinceEpoch}@example.com';
  const password = 'password123';

  try {
    final registered = await api.register(email: email, password: password);
    stdout.writeln('register  -> ${registered.user.email} (${registered.user.id})');

    final loggedIn = await api.signIn(email: email, password: password);
    stdout.writeln('login     -> ${loggedIn.user.id}');

    final me = await api.getCurrentUser(accessToken: loggedIn.accessToken);
    stdout.writeln('me        -> ${me.email}, onboarding=${me.hasCompletedOnboarding}');

    final refreshed = await api.refresh(refreshToken: loggedIn.refreshToken);
    stdout.writeln('refresh   -> ${refreshed.accessToken.substring(0, 12)}...');

    await api.signOut(refreshToken: refreshed.refreshToken);
    stdout.writeln('logout    -> ok');
    stdout.writeln('ALL CHECKS PASSED');
  } on SocketException catch (e) {
    stderr.writeln('Cannot reach backend: $e');
    stderr.writeln('Start it with: node backend/src/server.js');
    exitCode = 1;
  } catch (e) {
    stderr.writeln('FAILED: $e');
    exitCode = 1;
  }
}
