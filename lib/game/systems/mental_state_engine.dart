import 'package:material_ui/material_ui.dart';
import '../../../core/theme/app_colors.dart';
import '../../../domain/entities/room_state.dart';
import '../safe_room_game.dart';
import '../components/room/room_component.dart';

/// Engine that maps emotional states to environment effects
class MentalStateEngine {
  final SafeRoomGame game;
  EmotionalState _currentState = EmotionalState.calm;

  MentalStateEngine({required this.game});

  /// Update the emotional state and apply environment changes
  void updateEmotionalState(EmotionalState state) {
    _currentState = state;
    _applyEnvironmentEffects();
  }

  void _applyEnvironmentEffects() {
    // Get gradient colors for current emotion
    final colors = _getEmotionalGradient(_currentState);
    
    // Update room colors
    final room = game.children.whereType<RoomComponent>().firstOrNull;
    room?.updateEmotionalColors(colors);

    // Apply weather effects (would be more complex with particle systems)
    // For now, we just change the background
  }

  List<Color> _getEmotionalGradient(EmotionalState state) {
    switch (state) {
      case EmotionalState.calm:
        return AppColors.calmGradient;
      case EmotionalState.happy:
        return AppColors.happyGradient;
      case EmotionalState.sad:
        return AppColors.sadGradient;
      case EmotionalState.angry:
        return AppColors.angryGradient;
      case EmotionalState.anxious:
        return AppColors.anxiousGradient;
    }
  }

  /// Get environment description for current state
  String getEnvironmentDescription() {
    switch (_currentState) {
      case EmotionalState.calm:
        return 'Bright and peaceful room';
      case EmotionalState.happy:
        return 'Sunny room with growing plants';
      case EmotionalState.sad:
        return 'Rainy atmosphere';
      case EmotionalState.angry:
        return 'Dark sky, some items are broken';
      case EmotionalState.anxious:
        return 'Flickering lights';
    }
  }

  /// Check if objects should appear broken
  bool get objectsBroken => _currentState == EmotionalState.angry;

  /// Get current weather type
  WeatherType get weather => RoomState.weatherForEmotion(_currentState);

  /// Get room brightness
  double get brightness => RoomState.brightnessForEmotion(_currentState);
}
