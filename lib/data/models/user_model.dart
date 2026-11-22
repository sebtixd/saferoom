import '../../domain/entities/user.dart';
import '../../domain/entities/emotional_profile.dart';

/// Data model for User entity
class UserModel extends User {
  const UserModel({
    required super.id,
    super.email,
    required super.isAnonymous,
    required super.createdAt,
    super.emotionalProfile,
    super.points,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as String,
      email: json['email'] as String?,
      isAnonymous: json['is_anonymous'] as bool? ?? false,
      createdAt: DateTime.parse(json['created_at'] as String),
      emotionalProfile: json['emotional_profile'] != null
          ? EmotionalProfileModel.fromJson(
              json['emotional_profile'] as Map<String, dynamic>)
          : null,
      points: json['points'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'is_anonymous': isAnonymous,
      'created_at': createdAt.toIso8601String(),
      'points': points,
    };
  }

  factory UserModel.fromEntity(User user) {
    return UserModel(
      id: user.id,
      email: user.email,
      isAnonymous: user.isAnonymous,
      createdAt: user.createdAt,
      emotionalProfile: user.emotionalProfile,
      points: user.points,
    );
  }
}

/// Data model for EmotionalProfile entity
class EmotionalProfileModel extends EmotionalProfile {
  const EmotionalProfileModel({
    required super.id,
    required super.oduyId,
    required super.moodBaseline,
    required super.stressLevel,
    required super.energyLevel,
    required super.happinessTriggers,
    required super.angerTriggers,
    required super.calmingFactors,
    required super.preferredColor,
    super.spiritualPreference,
    required super.workRhythm,
    required super.createdAt,
    required super.updatedAt,
  });

  factory EmotionalProfileModel.fromJson(Map<String, dynamic> json) {
    return EmotionalProfileModel(
      id: json['id'] as String,
      oduyId: json['user_id'] as String,
      moodBaseline: json['mood_baseline'] as int,
      stressLevel: json['stress_level'] as int,
      energyLevel: json['energy_level'] as int,
      happinessTriggers:
          List<String>.from(json['happiness_triggers'] as List? ?? []),
      angerTriggers: List<String>.from(json['anger_triggers'] as List? ?? []),
      calmingFactors:
          List<String>.from(json['calming_factors'] as List? ?? []),
      preferredColor: json['preferred_color'] as String? ?? '#6B5CE7',
      spiritualPreference: json['spiritual_preference'] as String?,
      workRhythm: json['work_rhythm'] as String? ?? 'regular',
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': oduyId,
      'mood_baseline': moodBaseline,
      'stress_level': stressLevel,
      'energy_level': energyLevel,
      'happiness_triggers': happinessTriggers,
      'anger_triggers': angerTriggers,
      'calming_factors': calmingFactors,
      'preferred_color': preferredColor,
      'spiritual_preference': spiritualPreference,
      'work_rhythm': workRhythm,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory EmotionalProfileModel.fromEntity(EmotionalProfile profile) {
    return EmotionalProfileModel(
      id: profile.id,
      oduyId: profile.oduyId,
      moodBaseline: profile.moodBaseline,
      stressLevel: profile.stressLevel,
      energyLevel: profile.energyLevel,
      happinessTriggers: profile.happinessTriggers,
      angerTriggers: profile.angerTriggers,
      calmingFactors: profile.calmingFactors,
      preferredColor: profile.preferredColor,
      spiritualPreference: profile.spiritualPreference,
      workRhythm: profile.workRhythm,
      createdAt: profile.createdAt,
      updatedAt: profile.updatedAt,
    );
  }
}
