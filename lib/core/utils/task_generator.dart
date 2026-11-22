import 'dart:math';
import '../../domain/entities/daily_task.dart';
import '../../domain/entities/emotional_profile.dart';

/// Helper class to generate personalized tasks based on emotional profile
class TaskGenerator {
  static final _random = Random();

  /// High Stress Tasks (Stress > 6)
  static const _highStressTasks = [
    'Take 5 deep breaths focusing on your exhale',
    'Write down one worry and one action step to address it',
    'Do a 2-minute body scan meditation',
    'Step away from screens for 5 minutes',
    'Listen to calming rain sounds for 5 minutes',
    'Practice the 4-7-8 breathing technique',
    'Stretch your neck and shoulders gently',
    'Drink a glass of water slowly',
    'Write down 3 things you can control right now',
    'Take a short walk outside for fresh air',
  ];

  /// Low Energy Tasks (Energy < 4)
  static const _lowEnergyTasks = [
    'Take a 10-minute power nap',
    'Drink a glass of water and stretch for 2 minutes',
    'Listen to your favorite uplifting song',
    'Stand up and shake out your limbs',
    'Eat a piece of fruit',
    'Open the curtains to let in natural light',
    'Splash cold water on your face',
    'Do 5 jumping jacks',
    'Call a friend for a quick 5-minute chat',
    'Step outside and take 3 deep breaths',
  ];

  /// Mood Boosting Tasks (Mood < 5)
  static const _moodBoostingTasks = [
    'List 3 things you\'re grateful for today',
    'Send a kind message to a friend or family member',
    'Watch a funny video or read a funny comic',
    'Do something creative for 10 minutes',
    'Wear your favorite comfortable outfit',
    'Listen to an energetic playlist',
    'Organize one small area of your desk/room',
    'Plan a nice treat for yourself this evening',
    'Compliment someone today',
    'Look at photos of happy memories',
  ];

  /// General Wellness / Maintenance Tasks
  static const _generalWellnessTasks = [
    'Spend 5 minutes in nature or by a window',
    'Journal about your day for 5 minutes',
    'Practice mindful eating with one meal',
    'Read 5 pages of a book',
    'Go to bed 15 minutes earlier than usual',
    'Declutter your workspace for 5 minutes',
    'Try a new healthy snack',
    'Hydrate: Drink 200ml of water',
    'Plan your top 3 priorities for tomorrow',
    'Take a photo of something beautiful',
  ];

  /// Generate 3 tasks based on user profile
  static List<TaskItem> generate(EmotionalProfile? profile) {
    if (profile == null) {
      return _generateDefaultTasks();
    }

    final tasks = <String>{}; // Use Set to avoid duplicates
    
    // Task 1: Address Stress
    if (profile.stressLevel > 6) {
      tasks.add(_getRandom(_highStressTasks));
    } else {
      tasks.add(_getRandom(_generalWellnessTasks));
    }
    
    // Task 2: Address Energy
    if (profile.energyLevel < 4) {
      tasks.add(_getRandom(_lowEnergyTasks));
    } else {
      // If energy is fine, focus on mood or general wellness
      if (profile.moodBaseline < 5) {
        tasks.add(_getRandom(_moodBoostingTasks));
      } else {
        tasks.add(_getRandom(_generalWellnessTasks));
      }
    }
    
    // Task 3: Address Mood
    if (profile.moodBaseline < 5) {
      tasks.add(_getRandom(_moodBoostingTasks));
    } else {
      // If everything is relatively stable, mix in general tasks
      // that ideally use user's happiness triggers if we parsed them
      tasks.add(_getRandom(_generalWellnessTasks));
    }
    
    // Ensure we have exactly 3 unique tasks
    while (tasks.length < 3) {
      tasks.add(_getRandom(_generalWellnessTasks));
    }
    
    return tasks.take(3).map((text) => TaskItem(text: text)).toList();
  }

  static List<TaskItem> _generateDefaultTasks() {
    return _generalWellnessTasks
        .sublist(0, 3)
        .map((text) => TaskItem(text: text))
        .toList();
  }

  static String _getRandom(List<String> list) {
    return list[_random.nextInt(list.length)];
  }
}
