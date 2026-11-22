/// Game-related constants for the SafeRoom Flame game
class GameConstants {
  GameConstants._();

  // Room Dimensions
  static const double roomWidth = 800;
  static const double roomHeight = 600;

  // Character Settings
  static const double characterSpeed = 150.0;
  static const double characterSize = 48.0;

  // Object Positions (relative to room)
  static const Map<String, List<double>> objectPositions = {
    'desk': [100, 150],
    'notebook': [120, 170],
    'window': [400, 50],
    'bed': [600, 400],
    'pet': [300, 350],
    'prayerCorner': [650, 100],
  };

  // Object Sizes
  static const double deskWidth = 80;
  static const double deskHeight = 60;
  static const double windowWidth = 100;
  static const double windowHeight = 80;
  static const double bedWidth = 100;
  static const double bedHeight = 120;
  static const double petSize = 40;
  static const double prayerCornerSize = 60;

  // Interaction Range
  static const double interactionDistance = 60.0;

  // Animation Durations
  static const Duration walkAnimationDuration = Duration(milliseconds: 100);
  static const Duration interactionAnimationDuration = Duration(milliseconds: 300);
  static const Duration weatherTransitionDuration = Duration(seconds: 2);

  // Weather Effects
  static const double rainDropSpeed = 200.0;
  static const int maxRainDrops = 100;
  static const double lightFlickerIntensity = 0.3;

  // Colors for emotional states
  static const Map<String, int> emotionalColors = {
    'calm': 0xFFFFFACD, // Light yellow
    'happy': 0xFFFFE4B5, // Moccasin
    'sad': 0xFF778899, // Light slate gray
    'angry': 0xFFCD5C5C, // Indian red
    'anxious': 0xFFDDA0DD, // Plum
  };
}
