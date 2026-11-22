import 'package:equatable/equatable.dart';

/// Emotional state enumeration
enum EmotionalState { calm, happy, sad, angry, anxious }

/// Weather type enumeration
enum WeatherType { sunny, cloudy, rainy, stormy }

/// Room state entity representing the game environment
class RoomState extends Equatable {
  final String id;
  final String userId;
  final EmotionalState currentEmotion;
  final double brightness;
  final WeatherType weather;
  final bool objectsBroken;
  final int petHappiness;
  final Map<String, bool> objectsUnlocked;
  final Map<String, dynamic>? customization;
  final DateTime lastUpdated;

  const RoomState({
    required this.id,
    required this.userId,
    required this.currentEmotion,
    required this.brightness,
    required this.weather,
    required this.objectsBroken,
    required this.petHappiness,
    required this.objectsUnlocked,
    this.customization,
    required this.lastUpdated,
  });

  /// Factory for creating initial room state
  factory RoomState.initial(String userId) {
    return RoomState(
      id: '',
      userId: userId,
      currentEmotion: EmotionalState.calm,
      brightness: 1.0,
      weather: WeatherType.sunny,
      objectsBroken: false,
      petHappiness: 50,
      objectsUnlocked: {
        'desk': true,
        'notebook': true,
        'window': true,
        'bed': true,
        'pet': true,
        'prayerCorner': true,
      },
      customization: {},
      lastUpdated: DateTime.now(),
    );
  }

  /// Get weather based on emotional state
  static WeatherType weatherForEmotion(EmotionalState emotion) {
    switch (emotion) {
      case EmotionalState.calm:
      case EmotionalState.happy:
        return WeatherType.sunny;
      case EmotionalState.sad:
        return WeatherType.rainy;
      case EmotionalState.angry:
        return WeatherType.stormy;
      case EmotionalState.anxious:
        return WeatherType.cloudy;
    }
  }

  /// Get brightness based on emotional state
  static double brightnessForEmotion(EmotionalState emotion) {
    switch (emotion) {
      case EmotionalState.calm:
        return 1.0;
      case EmotionalState.happy:
        return 1.1;
      case EmotionalState.sad:
        return 0.6;
      case EmotionalState.angry:
        return 0.4;
      case EmotionalState.anxious:
        return 0.7;
    }
  }

  /// Create a copy with updated fields
  RoomState copyWith({
    String? id,
    String? userId,
    EmotionalState? currentEmotion,
    double? brightness,
    WeatherType? weather,
    bool? objectsBroken,
    int? petHappiness,
    Map<String, bool>? objectsUnlocked,
    Map<String, dynamic>? customization,
    DateTime? lastUpdated,
  }) {
    return RoomState(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      currentEmotion: currentEmotion ?? this.currentEmotion,
      brightness: brightness ?? this.brightness,
      weather: weather ?? this.weather,
      objectsBroken: objectsBroken ?? this.objectsBroken,
      petHappiness: petHappiness ?? this.petHappiness,
      objectsUnlocked: objectsUnlocked ?? this.objectsUnlocked,
      customization: customization ?? this.customization,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }

  @override
  List<Object?> get props => [
        id,
        userId,
        currentEmotion,
        brightness,
        weather,
        objectsBroken,
        petHappiness,
        objectsUnlocked,
        customization,
        lastUpdated,
      ];
}
