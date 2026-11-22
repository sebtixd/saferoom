import 'package:dartz/dartz.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'package:safe_room/core/errors/failures.dart';
import 'package:safe_room/data/datasources/local/room_customization_storage.dart';
import 'package:safe_room/domain/entities/emotional_profile.dart';
import 'package:safe_room/domain/entities/room_background.dart';
import 'package:safe_room/domain/entities/user.dart';
import 'package:safe_room/domain/repositories/user_repository.dart';
import 'package:safe_room/presentation/blocs/auth/auth_bloc.dart';
import 'package:safe_room/presentation/blocs/auth/auth_event.dart';
import 'package:safe_room/presentation/blocs/auth/auth_state.dart';
import 'package:safe_room/presentation/widgets/room_customization_shop.dart';

import 'helpers/fakes.dart';

class FakeUserRepository implements UserRepository {
  User? updated;

  @override
  Future<Either<Failure, User>> getUserById(String id) async => Right(testUser());

  @override
  Future<Either<Failure, User>> updateUser(User user) async {
    updated = user;
    return Right(user);
  }

  @override
  Future<Either<Failure, EmotionalProfile>> saveEmotionalProfile(
    EmotionalProfile profile,
  ) async =>
      Right(profile);

  @override
  Future<Either<Failure, EmotionalProfile?>> getEmotionalProfile(
    String userId,
  ) async =>
      const Right(null);

  @override
  Future<Either<Failure, EmotionalProfile>> updateEmotionalProfile(
    EmotionalProfile profile,
  ) async =>
      Right(profile);

  @override
  Future<bool> hasCompletedOnboarding(String userId) async => true;
}

class _FakeAuthBloc extends Bloc<AuthEvent, AuthState> implements AuthBloc {
  _FakeAuthBloc()
      : super(AuthAuthenticated(user: testUser().copyWith(points: 200))) {
    on<AuthUpdateUser>(
      (event, emit) => emit(AuthAuthenticated(user: event.user)),
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  testWidgets('equipping an owned background persists and notifies', (tester) async {
    final local = FakeLocalStorage();
    final storage = RoomCustomizationStorage(local);
    final userRepo = FakeUserRepository();
    RoomBackground? equipped;

    await storage.save(
      'user-1',
      RoomCustomizationStorage.catalog.map((b) {
        if (b.id == 'sunset') return b.copyWith(owned: true);
        return b;
      }).toList(),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: BlocProvider<AuthBloc>.value(
          value: _FakeAuthBloc(),
          child: Scaffold(
            body: RoomCustomizationShop(
              userId: 'user-1',
              storage: storage,
              userRepository: userRepo,
              onClose: () {},
              onBackgroundEquipped: (b) => equipped = b,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Sunset Glow').first);
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(ElevatedButton, 'Equip'));
    await tester.pumpAndSettle();

    expect(equipped?.id, 'sunset');
    final state = await storage.load('user-1');
    expect(state.equippedBackgroundId, 'sunset');
  });
}
