import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../domain/repositories/game_repository.dart';
import 'game_event.dart';
import 'game_state.dart';

/// Game BLoC
class GameBloc extends Bloc<GameEvent, GameState> {
  final GameRepository gameRepository;
  String? _currentUserId;

  GameBloc({
    required this.gameRepository,
  }) : super(const GameInitial()) {
    on<GameLoad>(_onLoad);
    on<GameUpdateEmotion>(_onUpdateEmotion);
    on<GameInteract>(_onInteract);
    on<GamePetInteract>(_onPetInteract);
    on<GameRepairObjects>(_onRepairObjects);
  }

  Future<void> _onLoad(
    GameLoad event,
    Emitter<GameState> emit,
  ) async {
    emit(const GameLoading());
    _currentUserId = event.userId;

    final result = await gameRepository.getRoomState(event.userId);

    result.fold(
      (failure) => emit(GameError(failure.message)),
      (roomState) => emit(GameLoaded(roomState: roomState)),
    );
  }

  Future<void> _onUpdateEmotion(
    GameUpdateEmotion event,
    Emitter<GameState> emit,
  ) async {
    final currentState = state;
    if (currentState is! GameLoaded || _currentUserId == null) return;

    final result = await gameRepository.updateEmotionalState(
      userId: _currentUserId!,
      emotion: event.emotion,
    );

    result.fold(
      (failure) => emit(GameError(failure.message)),
      (roomState) => emit(currentState.copyWith(roomState: roomState)),
    );
  }

  Future<void> _onInteract(
    GameInteract event,
    Emitter<GameState> emit,
  ) async {
    final currentState = state;
    if (currentState is! GameLoaded || _currentUserId == null) return;

    await gameRepository.recordInteraction(
      userId: _currentUserId!,
      objectId: event.objectId,
      interactionType: 'tap',
    );

    emit(currentState.copyWith(activeInteraction: event.objectId));
  }

  Future<void> _onPetInteract(
    GamePetInteract event,
    Emitter<GameState> emit,
  ) async {
    final currentState = state;
    if (currentState is! GameLoaded || _currentUserId == null) return;

    final result = await gameRepository.updatePetHappiness(
      userId: _currentUserId!,
      happinessChange: 15,
    );

    result.fold(
      (failure) => emit(GameError(failure.message)),
      (roomState) => emit(currentState.copyWith(roomState: roomState)),
    );
  }

  Future<void> _onRepairObjects(
    GameRepairObjects event,
    Emitter<GameState> emit,
  ) async {
    final currentState = state;
    if (currentState is! GameLoaded || _currentUserId == null) return;

    final result = await gameRepository.repairObjects(_currentUserId!);

    result.fold(
      (failure) => emit(GameError(failure.message)),
      (roomState) => emit(currentState.copyWith(roomState: roomState)),
    );
  }
}
