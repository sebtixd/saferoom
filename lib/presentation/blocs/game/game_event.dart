import 'package:equatable/equatable.dart';
import '../../../domain/entities/room_state.dart';

/// Game events
abstract class GameEvent extends Equatable {
  const GameEvent();

  @override
  List<Object?> get props => [];
}

/// Load game state
class GameLoad extends GameEvent {
  final String userId;
  const GameLoad(this.userId);

  @override
  List<Object?> get props => [userId];
}

/// Update emotional state
class GameUpdateEmotion extends GameEvent {
  final EmotionalState emotion;
  const GameUpdateEmotion(this.emotion);

  @override
  List<Object?> get props => [emotion];
}

/// Interact with object
class GameInteract extends GameEvent {
  final String objectId;
  const GameInteract(this.objectId);

  @override
  List<Object?> get props => [objectId];
}

/// Pet interaction
class GamePetInteract extends GameEvent {
  const GamePetInteract();
}

/// Repair room objects
class GameRepairObjects extends GameEvent {
  const GameRepairObjects();
}
