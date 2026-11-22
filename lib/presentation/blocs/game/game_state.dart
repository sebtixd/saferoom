import 'package:equatable/equatable.dart';
import '../../../domain/entities/room_state.dart';

/// Game states
abstract class GameState extends Equatable {
  const GameState();

  @override
  List<Object?> get props => [];
}

class GameInitial extends GameState {
  const GameInitial();
}

class GameLoading extends GameState {
  const GameLoading();
}

class GameLoaded extends GameState {
  final RoomState roomState;
  final String? activeInteraction;

  const GameLoaded({
    required this.roomState,
    this.activeInteraction,
  });

  GameLoaded copyWith({
    RoomState? roomState,
    String? activeInteraction,
  }) {
    return GameLoaded(
      roomState: roomState ?? this.roomState,
      activeInteraction: activeInteraction,
    );
  }

  @override
  List<Object?> get props => [roomState, activeInteraction];
}

class GameError extends GameState {
  final String message;

  const GameError(this.message);

  @override
  List<Object?> get props => [message];
}
