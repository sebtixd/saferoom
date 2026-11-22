import 'package:equatable/equatable.dart';

/// Onboarding states
class OnboardingState extends Equatable {
  final int currentStep;
  final int totalSteps;
  final int moodBaseline;
  final int stressLevel;
  final int energyLevel;
  final List<String> happinessTriggers;
  final List<String> angerTriggers;
  final List<String> calmingFactors;
  final String preferredColor;
  final String? spiritualPreference;
  final String workRhythm;
  final bool isLoading;
  final bool isCompleted;
  final String? error;

  const OnboardingState({
    this.currentStep = 0,
    this.totalSteps = 9,
    this.moodBaseline = 5,
    this.stressLevel = 5,
    this.energyLevel = 5,
    this.happinessTriggers = const [],
    this.angerTriggers = const [],
    this.calmingFactors = const [],
    this.preferredColor = '#6B5CE7',
    this.spiritualPreference,
    this.workRhythm = 'regular',
    this.isLoading = false,
    this.isCompleted = false,
    this.error,
  });

  OnboardingState copyWith({
    int? currentStep,
    int? totalSteps,
    int? moodBaseline,
    int? stressLevel,
    int? energyLevel,
    List<String>? happinessTriggers,
    List<String>? angerTriggers,
    List<String>? calmingFactors,
    String? preferredColor,
    String? spiritualPreference,
    String? workRhythm,
    bool? isLoading,
    bool? isCompleted,
    String? error,
  }) {
    return OnboardingState(
      currentStep: currentStep ?? this.currentStep,
      totalSteps: totalSteps ?? this.totalSteps,
      moodBaseline: moodBaseline ?? this.moodBaseline,
      stressLevel: stressLevel ?? this.stressLevel,
      energyLevel: energyLevel ?? this.energyLevel,
      happinessTriggers: happinessTriggers ?? this.happinessTriggers,
      angerTriggers: angerTriggers ?? this.angerTriggers,
      calmingFactors: calmingFactors ?? this.calmingFactors,
      preferredColor: preferredColor ?? this.preferredColor,
      spiritualPreference: spiritualPreference ?? this.spiritualPreference,
      workRhythm: workRhythm ?? this.workRhythm,
      isLoading: isLoading ?? this.isLoading,
      isCompleted: isCompleted ?? this.isCompleted,
      error: error,
    );
  }

  double get progress => (currentStep + 1) / totalSteps;

  @override
  List<Object?> get props => [
        currentStep,
        totalSteps,
        moodBaseline,
        stressLevel,
        energyLevel,
        happinessTriggers,
        angerTriggers,
        calmingFactors,
        preferredColor,
        spiritualPreference,
        workRhythm,
        isLoading,
        isCompleted,
        error,
      ];
}
