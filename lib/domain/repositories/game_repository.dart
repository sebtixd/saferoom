import 'package:dartz/dartz.dart';
import '../../core/errors/failures.dart';
import '../entities/room_state.dart';

/// Repository interface for game state operations
abstract class GameRepository {
  /// Get room state for user
  Future<Either<Failure, RoomState>> getRoomState(String userId);

  /// Save room state
  Future<Either<Failure, RoomState>> saveRoomState(RoomState roomState);

  /// Update emotional state
  Future<Either<Failure, RoomState>> updateEmotionalState({
    required String userId,
    required EmotionalState emotion,
  });

  /// Update pet happiness
  Future<Either<Failure, RoomState>> updatePetHappiness({
    required String userId,
    required int happinessChange,
  });

  /// Repair broken objects
  Future<Either<Failure, RoomState>> repairObjects(String userId);

  /// Unlock object
  Future<Either<Failure, RoomState>> unlockObject({
    required String userId,
    required String objectId,
  });

  /// Record interaction
  Future<Either<Failure, void>> recordInteraction({
    required String userId,
    required String objectId,
    required String interactionType,
  });
}
