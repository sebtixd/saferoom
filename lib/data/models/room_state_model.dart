import '../../domain/entities/room_state.dart';

/// Data model for RoomState entity
class RoomStateModel extends RoomState {
  const RoomStateModel({
    required super.id,
    required super.userId,
    required super.currentEmotion,
    required super.brightness,
    required super.weather,
    required super.objectsBroken,
    required super.petHappiness,
    required super.objectsUnlocked,
    super.customization,
    required super.lastUpdated,
  });

  factory RoomStateModel.fromJson(Map<String, dynamic> json) {
    return RoomStateModel(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      currentEmotion: _parseEmotionalState(json['current_emotion'] as String?),
      brightness: (json['brightness'] as num?)?.toDouble() ?? 1.0,
      weather: _parseWeatherType(json['weather'] as String?),
      objectsBroken: json['objects_broken'] as bool? ?? false,
      petHappiness: json['pet_happiness'] as int? ?? 50,
      objectsUnlocked: Map<String, bool>.from(
        json['objects_unlocked'] as Map? ?? {},
      ),
      customization: json['customization'] as Map<String, dynamic>?,
      lastUpdated: DateTime.parse(
        json['last_updated'] as String? ?? DateTime.now().toIso8601String(),
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'current_emotion': _emotionToString(currentEmotion),
      'brightness': brightness,
      'weather': _weatherToString(weather),
      'objects_broken': objectsBroken,
      'pet_happiness': petHappiness,
      'objects_unlocked': objectsUnlocked,
      'customization': customization,
      'last_updated': lastUpdated.toIso8601String(),
    };
  }

  static EmotionalState _parseEmotionalState(String? state) {
    switch (state) {
      case 'happy':
        return EmotionalState.happy;
      case 'sad':
        return EmotionalState.sad;
      case 'angry':
        return EmotionalState.angry;
      case 'anxious':
        return EmotionalState.anxious;
      default:
        return EmotionalState.calm;
    }
  }

  static WeatherType _parseWeatherType(String? weather) {
    switch (weather) {
      case 'cloudy':
        return WeatherType.cloudy;
      case 'rainy':
        return WeatherType.rainy;
      case 'stormy':
        return WeatherType.stormy;
      default:
        return WeatherType.sunny;
    }
  }

  String _emotionToString(EmotionalState emotion) {
    switch (emotion) {
      case EmotionalState.calm:
        return 'calm';
      case EmotionalState.happy:
        return 'happy';
      case EmotionalState.sad:
        return 'sad';
      case EmotionalState.angry:
        return 'angry';
      case EmotionalState.anxious:
        return 'anxious';
    }
  }

  String _weatherToString(WeatherType weather) {
    switch (weather) {
      case WeatherType.sunny:
        return 'sunny';
      case WeatherType.cloudy:
        return 'cloudy';
      case WeatherType.rainy:
        return 'rainy';
      case WeatherType.stormy:
        return 'stormy';
    }
  }

  factory RoomStateModel.fromEntity(RoomState state) {
    return RoomStateModel(
      id: state.id,
      userId: state.userId,
      currentEmotion: state.currentEmotion,
      brightness: state.brightness,
      weather: state.weather,
      objectsBroken: state.objectsBroken,
      petHappiness: state.petHappiness,
      objectsUnlocked: state.objectsUnlocked,
      customization: state.customization,
      lastUpdated: state.lastUpdated,
    );
  }
}
