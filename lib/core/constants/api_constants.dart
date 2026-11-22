import '../config/api_config.dart';

/// API configuration constants.
///
/// Secrets and environment-specific URLs live in [ApiConfig] and are supplied
/// via `--dart-define`; nothing sensitive is stored in source control.
class ApiConstants {
  ApiConstants._();

  // AI Service Configuration (Google Gemini API - free tier supported)
  // Get a free key at https://aistudio.google.com/apikey and pass via:
  // --dart-define=SAFEROOM_GEMINI_API_KEY=YOUR_KEY
  static const String aiModel = 'gemini-1.5-flash';
  static const String aiApiUrl =
      'https://generativelanguage.googleapis.com/v1beta/models/$aiModel:generateContent';
  static const String aiApiKey = ApiConfig.geminiApiKey;

  // Firestore Collection Names
  static const String tableUsers = 'users';
  static const String tableEmotionalProfiles = 'emotional_profiles';
  static const String tableChatMessages = 'chat_messages';
  static const String tableJournalEntries = 'journal_entries';
  static const String tableTasks = 'tasks';
  static const String tableDailyTasks = 'daily_tasks';
  static const String tableRoomStates = 'room_states';

  // API Timeouts
  static const Duration connectionTimeout = Duration(seconds: 30);
  static const Duration receiveTimeout = Duration(seconds: 30);
}
