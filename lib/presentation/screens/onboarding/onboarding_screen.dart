import 'package:material_ui/material_ui.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../injection_container.dart';
import '../../blocs/onboarding/onboarding_bloc.dart';
import '../../blocs/onboarding/onboarding_event.dart';
import '../../blocs/onboarding/onboarding_state.dart';
import '../../blocs/auth/auth_bloc.dart';
import '../../blocs/auth/auth_state.dart';

import '../home/home_screen.dart';

/// Multi-step onboarding screen
class OnboardingScreen extends StatelessWidget {
  const OnboardingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<OnboardingBloc>(),
      child: const _OnboardingContent(),
    );
  }
}

class _OnboardingContent extends StatelessWidget {
  const _OnboardingContent();

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<OnboardingBloc, OnboardingState>(
      listener: (context, state) {
        if (state.isCompleted) {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (_) => const HomeScreen()),
            (route) => false,
          );
        } else if (state.error != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.error!),
              backgroundColor: Colors.red,
            ),
          );
        }
      },
      builder: (context, state) {
        return Scaffold(
          body: SafeArea(
            child: Column(
              children: [
                // Progress indicator
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      LinearProgressIndicator(
                        value: state.progress,
                        backgroundColor: Colors.grey[200],
                        color: const Color(0xFF6B5CE7),
                        minHeight: 6,
                        borderRadius: BorderRadius.circular(3),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Step ${state.currentStep + 1} of ${state.totalSteps}',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
                // Step content
                Expanded(
                  child: _buildStepContent(context, state),
                ),
                // Navigation buttons
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Row(
                    children: [
                      if (state.currentStep > 0)
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () {
                              context.read<OnboardingBloc>().add(const OnboardingPreviousStep());
                            },
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                            ),
                            child: const Text('Back'),
                          ),
                        ),
                      if (state.currentStep > 0) const SizedBox(width: 16),
                      Expanded(
                        flex: 2,
                        child: ElevatedButton(
                          onPressed: state.isLoading
                              ? null
                              : () {
                                  if (state.currentStep == state.totalSteps - 1) {
                                    final authState = context.read<AuthBloc>().state;
                                    final userId = (authState is AuthAuthenticated) ? authState.user.id : '';
                                    
                                    // Submit
                                    context.read<OnboardingBloc>().add(
                                      OnboardingSubmitted(userId),
                                    );
                                  } else {
                                    context.read<OnboardingBloc>().add(const OnboardingNextStep());
                                  }
                                },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF6B5CE7),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                          child: state.isLoading
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : Text(
                                  state.currentStep == state.totalSteps - 1 ? 'Complete' : 'Next',
                                  style: const TextStyle(fontSize: 16),
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildStepContent(BuildContext context, OnboardingState state) {
    switch (state.currentStep) {
      case 0:
        return _MoodStep(value: state.moodBaseline);
      case 1:
        return _StressStep(value: state.stressLevel);
      case 2:
        return _EnergyStep(value: state.energyLevel);
      case 3:
        return _HappinessTriggersStep(triggers: state.happinessTriggers);
      case 4:
        return _AngerTriggersStep(triggers: state.angerTriggers);
      case 5:
        return _CalmingFactorsStep(factors: state.calmingFactors);
      case 6:
        return _ColorStep(color: state.preferredColor);
      case 7:
        return _SpiritualStep(preference: state.spiritualPreference);
      case 8:
        return _WorkRhythmStep(rhythm: state.workRhythm);
      default:
        return const SizedBox();
    }
  }
}

// Step widgets
class _MoodStep extends StatelessWidget {
  final int value;
  const _MoodStep({required this.value});

  @override
  Widget build(BuildContext context) {
    return _SliderStep(
      title: 'How would you rate your typical mood?',
      subtitle: 'On a scale of 1 (low) to 10 (high)',
      value: value,
      onChanged: (v) => context.read<OnboardingBloc>().add(OnboardingMoodUpdated(v)),
    );
  }
}

class _StressStep extends StatelessWidget {
  final int value;
  const _StressStep({required this.value});

  @override
  Widget build(BuildContext context) {
    return _SliderStep(
      title: 'What is your current stress level?',
      subtitle: '1 = Very calm, 10 = Very stressed',
      value: value,
      onChanged: (v) => context.read<OnboardingBloc>().add(OnboardingStressUpdated(v)),
    );
  }
}

class _EnergyStep extends StatelessWidget {
  final int value;
  const _EnergyStep({required this.value});

  @override
  Widget build(BuildContext context) {
    return _SliderStep(
      title: 'How is your energy level?',
      subtitle: '1 = Very tired, 10 = Very energetic',
      value: value,
      onChanged: (v) => context.read<OnboardingBloc>().add(OnboardingEnergyUpdated(v)),
    );
  }
}

class _SliderStep extends StatelessWidget {
  final String title;
  final String subtitle;
  final int value;
  final ValueChanged<int> onChanged;

  const _SliderStep({
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 48),
          Text(
            '$value',
            style: const TextStyle(
              fontSize: 64,
              fontWeight: FontWeight.bold,
              color: Color(0xFF6B5CE7),
            ),
          ),
          const SizedBox(height: 24),
          Slider(
            value: value.toDouble(),
            min: 1,
            max: 10,
            divisions: 9,
            activeColor: const Color(0xFF6B5CE7),
            onChanged: (v) => onChanged(v.round()),
          ),
        ],
      ),
    );
  }
}

class _HappinessTriggersStep extends StatelessWidget {
  final List<String> triggers;
  const _HappinessTriggersStep({required this.triggers});

  @override
  Widget build(BuildContext context) {
    return _ChipSelectStep(
      title: 'What makes you happy?',
      subtitle: 'Select all that apply',
      options: const ['Family', 'Friends', 'Nature', 'Music', 'Exercise', 'Reading', 'Cooking', 'Gaming', 'Art', 'Meditation'],
      selected: triggers,
      onChanged: (v) => context.read<OnboardingBloc>().add(OnboardingHappinessTriggersUpdated(v)),
    );
  }
}

class _AngerTriggersStep extends StatelessWidget {
  final List<String> triggers;
  const _AngerTriggersStep({required this.triggers});

  @override
  Widget build(BuildContext context) {
    return _ChipSelectStep(
      title: 'What triggers your anger?',
      subtitle: 'Understanding helps manage emotions',
      options: const ['Work stress', 'Traffic', 'Lack of sleep', 'Injustice', 'Disrespect', 'Noise', 'Crowds', 'Delays', 'Health issues'],
      selected: triggers,
      onChanged: (v) => context.read<OnboardingBloc>().add(OnboardingAngerTriggersUpdated(v)),
    );
  }
}

class _CalmingFactorsStep extends StatelessWidget {
  final List<String> factors;
  const _CalmingFactorsStep({required this.factors});

  @override
  Widget build(BuildContext context) {
    return _ChipSelectStep(
      title: 'What calms you down?',
      subtitle: 'Activities that bring you peace',
      options: const ['Deep breathing', 'Nature walks', 'Music', 'Meditation', 'Prayer', 'Hot bath', 'Tea/Coffee', 'Journaling', 'Sleep'],
      selected: factors,
      onChanged: (v) => context.read<OnboardingBloc>().add(OnboardingCalmingFactorsUpdated(v)),
    );
  }
}

class _ChipSelectStep extends StatelessWidget {
  final String title;
  final String subtitle;
  final List<String> options;
  final List<String> selected;
  final ValueChanged<List<String>> onChanged;

  const _ChipSelectStep({
    required this.title,
    required this.subtitle,
    required this.options,
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: TextStyle(fontSize: 16, color: Colors.grey[600]),
          ),
          const SizedBox(height: 24),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: options.map((option) {
              final isSelected = selected.contains(option);
              return FilterChip(
                label: Text(option),
                selected: isSelected,
                selectedColor: const Color(0xFF6B5CE7).withValues(alpha: 0.2),
                checkmarkColor: const Color(0xFF6B5CE7),
                onSelected: (_) {
                  final newSelected = List<String>.from(selected);
                  if (isSelected) {
                    newSelected.remove(option);
                  } else {
                    newSelected.add(option);
                  }
                  onChanged(newSelected);
                },
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

class _ColorStep extends StatelessWidget {
  final String color;
  const _ColorStep({required this.color});

  @override
  Widget build(BuildContext context) {
    final colors = [
      '#6B5CE7', '#00BFA5', '#FF6B6B', '#FFD93D', '#6BCB77',
      '#4D96FF', '#FF8C00', '#9D4EDD', '#2EC4B6', '#FF69B4',
    ];
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Choose your preferred color',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'This will personalize your SafeRoom',
            style: TextStyle(fontSize: 16, color: Colors.grey[600]),
          ),
          const SizedBox(height: 32),
          Wrap(
            spacing: 16,
            runSpacing: 16,
            children: colors.map((c) {
              final isSelected = c == color;
              return GestureDetector(
                onTap: () => context.read<OnboardingBloc>().add(OnboardingColorUpdated(c)),
                child: Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: Color(int.parse(c.replaceFirst('#', '0xFF'))),
                    borderRadius: BorderRadius.circular(16),
                    border: isSelected ? Border.all(color: Colors.black, width: 3) : null,
                  ),
                  child: isSelected ? const Icon(Icons.check, color: Colors.white) : null,
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

class _SpiritualStep extends StatelessWidget {
  final String? preference;
  const _SpiritualStep({required this.preference});

  @override
  Widget build(BuildContext context) {
    final options = ['Islam', 'Christianity', 'Buddhism', 'Hinduism', 'Other', 'Prefer not to say'];
    return RadioGroup<String>(
      groupValue: preference,
      onChanged: (v) => context.read<OnboardingBloc>().add(OnboardingSpiritualUpdated(v)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Spiritual preference (optional)',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'This helps personalize spiritual content',
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            ),
            const SizedBox(height: 24),
            ...options.map((option) {
              return RadioListTile<String>(
                title: Text(option),
                value: option,
                activeColor: const Color(0xFF6B5CE7),
              );
            }),
          ],
        ),
      ),
    );
  }
}

class _WorkRhythmStep extends StatelessWidget {
  final String rhythm;
  const _WorkRhythmStep({required this.rhythm});

  @override
  Widget build(BuildContext context) {
    final options = [
      ('Regular 9-5', 'regular'),
      ('Flexible hours', 'flexible'),
      ('Night shifts', 'night'),
      ('Student schedule', 'student'),
      ('Freelancer', 'freelancer'),
    ];
    return RadioGroup<String>(
      groupValue: rhythm,
      onChanged: (v) {
        if (v != null) {
          context.read<OnboardingBloc>().add(OnboardingWorkRhythmUpdated(v));
        }
      },
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'What\'s your work/study rhythm?',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Helps tailor task timing',
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            ),
            const SizedBox(height: 24),
            ...options.map((option) {
              return RadioListTile<String>(
                title: Text(option.$1),
                value: option.$2,
                activeColor: const Color(0xFF6B5CE7),
              );
            }),
          ],
        ),
      ),
    );
  }
}
