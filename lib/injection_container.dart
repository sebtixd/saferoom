import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;

// Data Sources
import 'data/datasources/local/local_storage_service.dart';
import 'data/datasources/local/notes_storage.dart';
import 'data/datasources/local/room_customization_storage.dart';
import 'data/datasources/local/token_storage.dart';
import 'data/datasources/remote/firebase_service.dart';
import 'data/datasources/remote/api_client.dart';
import 'data/datasources/remote/auth_api_service.dart';
import 'data/datasources/remote/task_api_service.dart';
import 'data/datasources/remote/ai_service.dart';

// Repositories
import 'domain/repositories/auth_repository.dart';
import 'domain/repositories/user_repository.dart';
import 'domain/repositories/chat_repository.dart';
import 'domain/repositories/journal_repository.dart';
import 'domain/repositories/task_repository.dart';
import 'domain/repositories/game_repository.dart';

import 'data/repositories/auth_repository_impl.dart';
import 'data/repositories/user_repository_impl.dart';
import 'data/repositories/chat_repository_impl.dart';
import 'data/repositories/journal_repository_impl.dart';
import 'data/repositories/task_repository_impl.dart';
import 'data/repositories/game_repository_impl.dart';

// Use Cases
import 'domain/usecases/auth/get_current_user_usecase.dart';
import 'domain/usecases/auth/login_usecase.dart';
import 'domain/usecases/auth/register_usecase.dart';
import 'domain/usecases/auth/logout_usecase.dart';
import 'domain/usecases/onboarding/save_emotional_profile_usecase.dart';
import 'domain/usecases/chat/send_message_usecase.dart';
import 'domain/usecases/chat/get_chat_history_usecase.dart';
import 'domain/usecases/journal/save_journal_entry_usecase.dart';
import 'domain/usecases/journal/get_journal_entries_usecase.dart';
import 'domain/usecases/task/get_todays_tasks_usecase.dart';
import 'domain/usecases/task/toggle_task_completion_usecase.dart';
import 'domain/usecases/ai/analyze_emotion_usecase.dart';
import 'domain/usecases/ai/weekly_analysis_usecase.dart';

// BLoCs
import 'presentation/blocs/auth/auth_bloc.dart';
import 'presentation/blocs/onboarding/onboarding_bloc.dart';
import 'presentation/blocs/chat/chat_bloc.dart';
import 'presentation/blocs/journal/journal_bloc.dart';
import 'presentation/blocs/task/task_bloc.dart';
import 'presentation/blocs/game/game_bloc.dart';

final sl = GetIt.instance;

Future<void> init() async {
  //! External
  final sharedPreferences = await SharedPreferences.getInstance();
  sl.registerLazySingleton(() => sharedPreferences);
  sl.registerLazySingleton(() => FirebaseAuth.instance);
  sl.registerLazySingleton(() => FirebaseFirestore.instance);
  sl.registerLazySingleton(() => http.Client());

  //! Data Sources
  sl.registerLazySingleton<LocalStorageService>(
    () => LocalStorageServiceImpl(sl()),
  );
  sl.registerLazySingleton<NotesStorage>(
    () => SharedPreferencesNotesStorage(sl()),
  );
  sl.registerLazySingleton<RoomCustomizationStorage>(
    () => RoomCustomizationStorage(sl()),
  );
  sl.registerLazySingleton<TokenStorage>(() => SecureTokenStorage());
  sl.registerLazySingleton(() => ApiClient(sl()));
  sl.registerLazySingleton<AuthApiService>(() => AuthApiService(sl()));
  sl.registerLazySingleton<TaskApiService>(() => TaskApiService(sl(), sl(), sl()));
  sl.registerLazySingleton<FirebaseService>(
    () => FirebaseServiceImpl(sl(), sl()),
  );
  sl.registerLazySingleton<AIService>(
    () => AIServiceImpl(),
  );

  //! Repositories
  sl.registerLazySingleton<AuthRepository>(
    () => AuthRepositoryImpl(sl(), sl(), sl()),
  );
  sl.registerLazySingleton<UserRepository>(
    () => UserRepositoryImpl(sl(), sl(), sl()),
  );
  sl.registerLazySingleton<ChatRepository>(
    () => ChatRepositoryImpl(sl(), sl()),
  );
  sl.registerLazySingleton<JournalRepository>(
    () => JournalRepositoryImpl(sl()),
  );
  sl.registerLazySingleton<TaskRepository>(
    () => TaskRepositoryImpl(sl(), sl(), sl(), sl(), sl()),
  );
  sl.registerLazySingleton<GameRepository>(
    () => GameRepositoryImpl(sl()),
  );

  //! Use Cases
  sl.registerLazySingleton(() => LoginUseCase(sl()));
  sl.registerLazySingleton(() => RegisterUseCase(sl()));
  sl.registerLazySingleton(() => LogoutUseCase(sl()));
  sl.registerLazySingleton(() => GetCurrentUserUseCase(sl()));
  sl.registerLazySingleton(() => SaveEmotionalProfileUseCase(sl()));
  sl.registerLazySingleton(() => SendMessageUseCase(sl()));
  sl.registerLazySingleton(() => GetChatHistoryUseCase(sl()));
  sl.registerLazySingleton(() => SaveJournalEntryUseCase(sl()));
  sl.registerLazySingleton(() => GetJournalEntriesUseCase(sl()));
  sl.registerLazySingleton(() => GetTodaysTasksUseCase(sl()));
  sl.registerLazySingleton(() => ToggleTaskCompletionUseCase(sl()));
  sl.registerLazySingleton(() => AnalyzeEmotionUseCase(sl()));
  sl.registerLazySingleton(() => WeeklyAnalysisUseCase(sl()));

  //! BLoCs
  sl.registerLazySingleton(() => AuthBloc(
        loginUseCase: sl(),
        registerUseCase: sl(),
        logoutUseCase: sl(),
        getCurrentUserUseCase: sl(),
      ));
  sl.registerFactory(() => OnboardingBloc(
        saveEmotionalProfileUseCase: sl(),
      ));
  sl.registerFactory(() => ChatBloc(
        sendMessageUseCase: sl(),
        getChatHistoryUseCase: sl(),
        analyzeEmotionUseCase: sl(),
      ));
  sl.registerFactory(() => JournalBloc(
        saveJournalEntryUseCase: sl(),
        getJournalEntriesUseCase: sl(),
      ));
  sl.registerFactory(() => TaskBloc(
        getTodaysTasks: sl(),
        toggleTaskCompletion: sl(),
        authBloc: sl(),
      ));
  sl.registerFactory(() => GameBloc(
        gameRepository: sl(),
      ));
}
