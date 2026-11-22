/// Application-wide constants
class AppConstants {
  AppConstants._();

  // App Info
  static const String appName = 'SafeRoom';
  static const String appVersion = '1.0.0';

  // Onboarding
  static const int onboardingSteps = 9;
  static const int minMoodValue = 1;
  static const int maxMoodValue = 10;

  // Tasks
  static const int maxDailyTasks = 5;
  static const int weeklyAnalysisDays = 7;

  // Pet
  static const int maxPetHappiness = 100;
  static const int petHappinessDecayPerDay = 10;
  static const int petHappinessGainPerInteraction = 15;

  // Local Storage Keys
  static const String keyUserId = 'user_id';
  static const String keyIsLoggedIn = 'is_logged_in';
  static const String keyIsAnonymous = 'is_anonymous';
  static const String keyOnboardingComplete = 'onboarding_complete';
  static const String keyEmotionalProfile = 'emotional_profile';
  static const String keyRoomState = 'room_state';
  static const String keyLastLoginDate = 'last_login_date';
  static const String keyNotesPages = 'notes_pages';
}
