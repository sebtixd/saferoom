import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../domain/entities/emotional_profile.dart';
import '../../../domain/usecases/onboarding/save_emotional_profile_usecase.dart';
import 'onboarding_event.dart';
import 'onboarding_state.dart';

/// Onboarding BLoC
class OnboardingBloc extends Bloc<OnboardingEvent, OnboardingState> {
  final SaveEmotionalProfileUseCase saveEmotionalProfileUseCase;

  OnboardingBloc({
    required this.saveEmotionalProfileUseCase,
  }) : super(const OnboardingState()) {
    on<OnboardingNextStep>(_onNextStep);
    on<OnboardingPreviousStep>(_onPreviousStep);
    on<OnboardingMoodUpdated>(_onMoodUpdated);
    on<OnboardingStressUpdated>(_onStressUpdated);
    on<OnboardingEnergyUpdated>(_onEnergyUpdated);
    on<OnboardingHappinessTriggersUpdated>(_onHappinessTriggersUpdated);
    on<OnboardingAngerTriggersUpdated>(_onAngerTriggersUpdated);
    on<OnboardingCalmingFactorsUpdated>(_onCalmingFactorsUpdated);
    on<OnboardingColorUpdated>(_onColorUpdated);
    on<OnboardingSpiritualUpdated>(_onSpiritualUpdated);
    on<OnboardingWorkRhythmUpdated>(_onWorkRhythmUpdated);
    on<OnboardingSubmitted>(_onSubmitted);
  }

  void _onNextStep(OnboardingNextStep event, Emitter<OnboardingState> emit) {
    if (state.currentStep < state.totalSteps - 1) {
      emit(state.copyWith(currentStep: state.currentStep + 1));
    }
  }

  void _onPreviousStep(OnboardingPreviousStep event, Emitter<OnboardingState> emit) {
    if (state.currentStep > 0) {
      emit(state.copyWith(currentStep: state.currentStep - 1));
    }
  }

  void _onMoodUpdated(OnboardingMoodUpdated event, Emitter<OnboardingState> emit) {
    emit(state.copyWith(moodBaseline: event.mood));
  }

  void _onStressUpdated(OnboardingStressUpdated event, Emitter<OnboardingState> emit) {
    emit(state.copyWith(stressLevel: event.stress));
  }

  void _onEnergyUpdated(OnboardingEnergyUpdated event, Emitter<OnboardingState> emit) {
    emit(state.copyWith(energyLevel: event.energy));
  }

  void _onHappinessTriggersUpdated(
    OnboardingHappinessTriggersUpdated event,
    Emitter<OnboardingState> emit,
  ) {
    emit(state.copyWith(happinessTriggers: event.triggers));
  }

  void _onAngerTriggersUpdated(
    OnboardingAngerTriggersUpdated event,
    Emitter<OnboardingState> emit,
  ) {
    emit(state.copyWith(angerTriggers: event.triggers));
  }

  void _onCalmingFactorsUpdated(
    OnboardingCalmingFactorsUpdated event,
    Emitter<OnboardingState> emit,
  ) {
    emit(state.copyWith(calmingFactors: event.factors));
  }

  void _onColorUpdated(OnboardingColorUpdated event, Emitter<OnboardingState> emit) {
    emit(state.copyWith(preferredColor: event.color));
  }

  void _onSpiritualUpdated(OnboardingSpiritualUpdated event, Emitter<OnboardingState> emit) {
    emit(state.copyWith(spiritualPreference: event.preference));
  }

  void _onWorkRhythmUpdated(OnboardingWorkRhythmUpdated event, Emitter<OnboardingState> emit) {
    emit(state.copyWith(workRhythm: event.rhythm));
  }

  Future<void> _onSubmitted(
    OnboardingSubmitted event,
    Emitter<OnboardingState> emit,
  ) async {
    emit(state.copyWith(isLoading: true, error: null));

    final now = DateTime.now();
    final profile = _EmotionalProfileData(
      id: '',
      oduyId: event.userId,
      moodBaseline: state.moodBaseline,
      stressLevel: state.stressLevel,
      energyLevel: state.energyLevel,
      happinessTriggers: state.happinessTriggers,
      angerTriggers: state.angerTriggers,
      calmingFactors: state.calmingFactors,
      preferredColor: state.preferredColor,
      spiritualPreference: state.spiritualPreference,
      workRhythm: state.workRhythm,
      createdAt: now,
      updatedAt: now,
    );

    final result = await saveEmotionalProfileUseCase(profile);

    result.fold(
      (failure) => emit(state.copyWith(
        isLoading: false,
        error: failure.message,
      )),
      (_) => emit(state.copyWith(
        isLoading: false,
        isCompleted: true,
      )),
    );
  }
}

// Internal class for creating profile
class _EmotionalProfileData extends EmotionalProfile {
  const _EmotionalProfileData({
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
}
