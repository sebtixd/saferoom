import 'package:dartz/dartz.dart';
import 'package:uuid/uuid.dart';
import '../../core/constants/api_constants.dart';
import '../../core/errors/exceptions.dart' as app_exceptions;
import '../../core/errors/failures.dart';
import '../../domain/entities/room_state.dart';
import '../../domain/repositories/game_repository.dart';
import '../datasources/remote/firebase_service.dart';
import '../models/room_state_model.dart';

/// Implementation of [GameRepository]
class GameRepositoryImpl implements GameRepository {
  final FirebaseService _firebaseService;
  
  GameRepositoryImpl(this._firebaseService);

  @override
  Future<Either<Failure, RoomState>> getRoomState(String userId) async {
    try {
      final data = await _firebaseService.select(
        ApiConstants.tableRoomStates,
        filters: {'user_id': userId},
      );

      if (data.isNotEmpty) {
        return Right(RoomStateModel.fromJson(data.first));
      }

      // Create initial room state if not exists
      final initialState = RoomState.initial(userId);
      return await saveRoomState(initialState);
    } on app_exceptions.ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, RoomState>> saveRoomState(RoomState roomState) async {
    try {
      final stateModel = RoomStateModel(
        id: roomState.id.isEmpty ? const Uuid().v4() : roomState.id,
        userId: roomState.userId,
        currentEmotion: roomState.currentEmotion,
        brightness: roomState.brightness,
        weather: roomState.weather,
        objectsBroken: roomState.objectsBroken,
        petHappiness: roomState.petHappiness,
        objectsUnlocked: roomState.objectsUnlocked,
        customization: roomState.customization,
        lastUpdated: DateTime.now(),
      );

      final data = await _firebaseService.insert(
        ApiConstants.tableRoomStates,
        stateModel.toJson(),
      );

      return Right(RoomStateModel.fromJson(data));
    } on app_exceptions.ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, RoomState>> updateEmotionalState({
    required String userId,
    required EmotionalState emotion,
  }) async {
    try {
      final currentState = await getRoomState(userId);
      
      return await currentState.fold(
        (failure) => Left(failure),
        (state) async {
          final newWeather = RoomState.weatherForEmotion(emotion);
          final newBrightness = RoomState.brightnessForEmotion(emotion);
          final objectsBroken = emotion == EmotionalState.angry;

          final updatedState = state.copyWith(
            currentEmotion: emotion,
            weather: newWeather,
            brightness: newBrightness,
            objectsBroken: objectsBroken,
            lastUpdated: DateTime.now(),
          );

          final data = await _firebaseService.update(
            ApiConstants.tableRoomStates,
            state.id,
            RoomStateModel.fromEntity(updatedState).toJson(),
          );

          return Right(RoomStateModel.fromJson(data));
        },
      );
    } on app_exceptions.ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, RoomState>> updatePetHappiness({
    required String userId,
    required int happinessChange,
  }) async {
    try {
      final currentState = await getRoomState(userId);
      
      return await currentState.fold(
        (failure) => Left(failure),
        (state) async {
          final newHappiness = (state.petHappiness + happinessChange).clamp(0, 100);

          final updatedState = state.copyWith(
            petHappiness: newHappiness,
            lastUpdated: DateTime.now(),
          );

          final data = await _firebaseService.update(
            ApiConstants.tableRoomStates,
            state.id,
            RoomStateModel.fromEntity(updatedState).toJson(),
          );

          return Right(RoomStateModel.fromJson(data));
        },
      );
    } on app_exceptions.ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, RoomState>> repairObjects(String userId) async {
    try {
      final currentState = await getRoomState(userId);
      
      return await currentState.fold(
        (failure) => Left(failure),
        (state) async {
          final updatedState = state.copyWith(
            objectsBroken: false,
            lastUpdated: DateTime.now(),
          );

          final data = await _firebaseService.update(
            ApiConstants.tableRoomStates,
            state.id,
            RoomStateModel.fromEntity(updatedState).toJson(),
          );

          return Right(RoomStateModel.fromJson(data));
        },
      );
    } on app_exceptions.ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, RoomState>> unlockObject({
    required String userId,
    required String objectId,
  }) async {
    try {
      final currentState = await getRoomState(userId);
      
      return await currentState.fold(
        (failure) => Left(failure),
        (state) async {
          final newUnlocked = Map<String, bool>.from(state.objectsUnlocked);
          newUnlocked[objectId] = true;

          final updatedState = state.copyWith(
            objectsUnlocked: newUnlocked,
            lastUpdated: DateTime.now(),
          );

          final data = await _firebaseService.update(
            ApiConstants.tableRoomStates,
            state.id,
            RoomStateModel.fromEntity(updatedState).toJson(),
          );

          return Right(RoomStateModel.fromJson(data));
        },
      );
    } on app_exceptions.ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> recordInteraction({
    required String userId,
    required String objectId,
    required String interactionType,
  }) async {
    try {
      // Log interaction for analytics
      // This could be stored in a separate interactions table
      // For now, just update pet happiness on pet interaction
      if (objectId == 'pet') {
        await updatePetHappiness(userId: userId, happinessChange: 15);
      }
      
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }
}
