import 'package:equatable/equatable.dart';

/// Onboarding events
abstract class OnboardingEvent extends Equatable {
  const OnboardingEvent();

  @override
  List<Object?> get props => [];
}

/// Move to next step
class OnboardingNextStep extends OnboardingEvent {
  const OnboardingNextStep();
}

/// Move to previous step
class OnboardingPreviousStep extends OnboardingEvent {
  const OnboardingPreviousStep();
}

/// Update mood baseline
class OnboardingMoodUpdated extends OnboardingEvent {
  final int mood;
  const OnboardingMoodUpdated(this.mood);

  @override
  List<Object?> get props => [mood];
}

/// Update stress level
class OnboardingStressUpdated extends OnboardingEvent {
  final int stress;
  const OnboardingStressUpdated(this.stress);

  @override
  List<Object?> get props => [stress];
}

/// Update energy level
class OnboardingEnergyUpdated extends OnboardingEvent {
  final int energy;
  const OnboardingEnergyUpdated(this.energy);

  @override
  List<Object?> get props => [energy];
}

/// Update happiness triggers
class OnboardingHappinessTriggersUpdated extends OnboardingEvent {
  final List<String> triggers;
  const OnboardingHappinessTriggersUpdated(this.triggers);

  @override
  List<Object?> get props => [triggers];
}

/// Update anger triggers
class OnboardingAngerTriggersUpdated extends OnboardingEvent {
  final List<String> triggers;
  const OnboardingAngerTriggersUpdated(this.triggers);

  @override
  List<Object?> get props => [triggers];
}

/// Update calming factors
class OnboardingCalmingFactorsUpdated extends OnboardingEvent {
  final List<String> factors;
  const OnboardingCalmingFactorsUpdated(this.factors);

  @override
  List<Object?> get props => [factors];
}

/// Update preferred color
class OnboardingColorUpdated extends OnboardingEvent {
  final String color;
  const OnboardingColorUpdated(this.color);

  @override
  List<Object?> get props => [color];
}

/// Update spiritual preference
class OnboardingSpiritualUpdated extends OnboardingEvent {
  final String? preference;
  const OnboardingSpiritualUpdated(this.preference);

  @override
  List<Object?> get props => [preference];
}

/// Update work rhythm
class OnboardingWorkRhythmUpdated extends OnboardingEvent {
  final String rhythm;
  const OnboardingWorkRhythmUpdated(this.rhythm);

  @override
  List<Object?> get props => [rhythm];
}

/// Submit profile
class OnboardingSubmitted extends OnboardingEvent {
  final String userId;
  const OnboardingSubmitted(this.userId);

  @override
  List<Object?> get props => [userId];
}
