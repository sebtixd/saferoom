import 'package:equatable/equatable.dart';

/// Emotional profile entity capturing user's mental health baseline
class EmotionalProfile extends Equatable {
  final String id;
  final String oduyId;
  final int moodBaseline;
  final int stressLevel;
  final int energyLevel;
  final List<String> happinessTriggers;
  final List<String> angerTriggers;
  final List<String> calmingFactors;
  final String preferredColor;
  final String? spiritualPreference;
  final String workRhythm;
  final DateTime createdAt;
  final DateTime updatedAt;

  const EmotionalProfile({
    required this.id,
    required this.oduyId,
    required this.moodBaseline,
    required this.stressLevel,
    required this.energyLevel,
    required this.happinessTriggers,
    required this.angerTriggers,
    required this.calmingFactors,
    required this.preferredColor,
    this.spiritualPreference,
    required this.workRhythm,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Convert to JSON for storage
  Map<String, dynamic> toJson() {
    return {
      'emotionalProfile': {
        'moodBaseline': moodBaseline,
        'stressLevel': stressLevel,
        'energyLevel': energyLevel,
      },
      'triggers': angerTriggers,
      'calmingFactors': calmingFactors,
      'preferences': {
        'happinessTriggers': happinessTriggers,
        'preferredColor': preferredColor,
        'spiritualPreference': spiritualPreference,
        'workRhythm': workRhythm,
      },
    };
  }

  @override
  List<Object?> get props => [
        id,
        oduyId,
        moodBaseline,
        stressLevel,
        energyLevel,
        happinessTriggers,
        angerTriggers,
        calmingFactors,
        preferredColor,
        spiritualPreference,
        workRhythm,
        createdAt,
        updatedAt,
      ];
}
