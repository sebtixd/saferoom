# SafeRoom Architecture Document

## System Overview

SafeRoom is a mental health application combining gamification, AI assistance, and emotional tracking. The architecture follows Clean Architecture principles with clear separation of concerns.

```
┌─────────────────────────────────────────────────────────────┐
│                     Presentation Layer                       │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐  ┌──────────┐   │
│  │  BLoCs   │  │ Screens  │  │  Widgets │  │   Game   │   │
│  └──────────┘  └──────────┘  └──────────┘  └──────────┘   │
└─────────────────────────────────────────────────────────────┘
                             ↕
┌─────────────────────────────────────────────────────────────┐
│                      Domain Layer                            │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐                  │
│  │ Entities │  │Use Cases │  │Repository│                  │
│  │          │  │          │  │Interfaces│                  │
│  └──────────┘  └──────────┘  └──────────┘                  │
└─────────────────────────────────────────────────────────────┘
                             ↕
┌─────────────────────────────────────────────────────────────┐
│                       Data Layer                             │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐  ┌──────────┐   │
│  │  Models  │  │Repository│  │  Remote  │  │  Local   │   │
│  │          │  │   Impl   │  │  Source  │  │  Source  │   │
│  └──────────┘  └──────────┘  └──────────┘  └──────────┘   │
└─────────────────────────────────────────────────────────────┘
                             ↕
┌─────────────────────────────────────────────────────────────┐
│                    External Services                         │
│     Supabase    │    OpenAI    │  SharedPreferences         │
└─────────────────────────────────────────────────────────────┘
```

## Layer Details

### 1. Presentation Layer

#### Responsibilities

- Display UI
- Handle user input
- Manage UI state with BLoC
- Render game graphics (Flame)

#### Components

**BLoCs** (Business Logic Components)

```
AuthBloc
├── Events: Login, Register, Logout
├── States: Initial, Loading, Authenticated, Error
└── Dependencies: LoginUseCase, RegisterUseCase, LogoutUseCase

GameBloc
├── Events: LoadGame, UpdateRoomState, Interact
├── States: Loading, Loaded, Error
└── Dependencies: GameRepository

ChatBloc
├── Events: SendMessage, LoadHistory
├── States: Loading, Loaded, Sending, Error
└── Dependencies: SendMessageUseCase, GetChatHistoryUseCase

JournalBloc
├── Events: CreateEntry, LoadEntries, UpdateEntry
├── States: Loading, Loaded, Saving, Error
└── Dependencies: SaveJournalEntryUseCase, GetJournalEntriesUseCase

TaskBloc
├── Events: LoadTasks, CompleteTask, RefreshTasks
├── States: Loading, Loaded, Updating, Error
└── Dependencies: GetDailyTasksUseCase, CompleteTaskUseCase

OnboardingBloc
├── Events: SubmitProfile
├── States: Initial, Submitting, Complete, Error
└── Dependencies: SaveEmotionalProfileUseCase
```

**Screens**

```
SplashScreen → AuthScreen → OnboardingScreen → HomeScreen
                                                    ├── GameScreen (Room)
                                                    ├── ChatScreen (Lisa)
                                                    ├── JournalScreen
                                                    └── SettingsScreen
```

**Game Components** (Flame)

```
SafeRoomGame (FlameGame)
├── RoomComponent (Background)
├── PlayerComponent (Character)
├── DeskObject (Interactive)
├── WindowObject (Interactive)
├── BedObject (Interactive)
├── PetObject (Interactive)
└── PrayerCornerObject (Interactive)

MentalStateEngine
└── Maps emotions → environment effects
```

### 2. Domain Layer

#### Responsibilities

- Define business entities
- Define business rules (use cases)
- Define repository contracts
- Independent of frameworks

#### Entities

```dart
User
├── id: String
├── email: String?
├── isAnonymous: bool
├── displayName: String?
├── createdAt: DateTime
├── lastLoginAt: DateTime?
└── onboardingCompleted: bool

EmotionalProfile
├── userId: String
├── moodBaseline: int (1-10)
├── stressLevel: int (1-10)
├── energyLevel: int (1-10)
├── happinessTriggers: List<String>
├── angerTriggers: List<String>
├── calmingFactors: List<String>
├── preferredColors: List<String>
├── spiritualPreferences: String?
└── workStudyRhythm: String?

ChatMessage
├── id: String
├── userId: String
├── role: String (user|assistant)
├── content: String
├── emotionDetected: String?
├── topic: String?
└── timestamp: DateTime

JournalEntry
├── id: String
├── userId: String
├── title: String
├── content: String
├── mood: String?
├── tags: List<String>
├── analyzed: bool
├── createdAt: DateTime
└── updatedAt: DateTime

Task
├── id: String
├── userId: String
├── title: String
├── description: String?
├── type: String (generic|personalized)
├── status: String (pending|completed)
├── category: String?
├── estimatedDuration: String?
├── createdAt: DateTime
├── completedAt: DateTime?
└── dueDate: DateTime?

RoomState
├── userId: String
├── currentEmotion: String
├── petHappiness: int (0-100)
├── objectStates: Map<String, int>
├── interactionCounts: Map<String, int>
├── unlockedItems: List<String>
├── environmentEffects: Map<String, dynamic>
├── lastUpdated: DateTime
└── lastPetInteraction: DateTime

WeeklyAnalysis
├── id: String
├── userId: String
├── weekStartDate: DateTime
├── weekEndDate: DateTime
├── emotionalTrends: EmotionalTrends
├── patterns: List<Pattern>
├── strengths: List<String>
├── recommendations: List<String>
├── personalizedTasks: List<PersonalizedTask>
└── metrics: AnalysisMetrics
```

#### Use Cases

Each use case represents one business action:

```dart
// Authentication
LoginUseCase(email, password) → Either<Failure, User>
RegisterUseCase(email, password) → Either<Failure, User>
LogoutUseCase() → Either<Failure, void>

// Onboarding
SaveEmotionalProfileUseCase(profile) → Either<Failure, EmotionalProfile>

// Chat
SendMessageUseCase(message) → Either<Failure, ChatMessage>
GetChatHistoryUseCase(userId) → Either<Failure, List<ChatMessage>>

// Journal
SaveJournalEntryUseCase(entry) → Either<Failure, JournalEntry>
GetJournalEntriesUseCase(userId) → Either<Failure, List<JournalEntry>>

// Tasks
GetDailyTasksUseCase(userId, date) → Either<Failure, List<Task>>
CompleteTaskUseCase(taskId) → Either<Failure, Task>

// AI
AnalyzeEmotionUseCase(text) → Either<Failure, String>
WeeklyAnalysisUseCase(userId) → Either<Failure, WeeklyAnalysis>
```

### 3. Data Layer

#### Responsibilities

- Implement repository interfaces
- Convert between entities and models
- Handle data sources (local/remote)
- Manage caching strategies

#### Models

Models extend entities with JSON serialization:

```dart
class UserModel extends User {
  UserModel(...);

  factory UserModel.fromJson(Map<String, dynamic> json);
  Map<String, dynamic> toJson();
  User toEntity();
}

// Same pattern for all entities
ChatMessageModel extends ChatMessage
JournalEntryModel extends JournalEntry
TaskModel extends Task
RoomStateModel extends RoomState
etc.
```

#### Data Sources

**LocalStorageService** (SharedPreferences)

```dart
interface LocalStorageService {
  Future<void> saveString(key, value);
  Future<String?> getString(key);
  Future<void> saveBool(key, value);
  Future<bool?> getBool(key);
  Future<void> saveJson(key, json);
  Future<Map<String, dynamic>?> getJson(key);
  Future<void> remove(key);
  Future<void> clear();
}
```

**SupabaseService** (Remote Database)

```dart
interface SupabaseService {
  // Auth
  Future<AuthResponse> signInWithEmail(email, password);
  Future<AuthResponse> signUpWithEmail(email, password);
  Future<AuthResponse> signInAnonymously();
  Future<void> signOut();
  User? getCurrentUser();

  // Database
  Future<List<Map<String, dynamic>>> query(table, {filters, order});
  Future<Map<String, dynamic>> insert(table, data);
  Future<Map<String, dynamic>> update(table, id, data);
  Future<void> delete(table, id);

  // Realtime
  Stream<List<Map<String, dynamic>>> subscribe(table, {filters});
}
```

**AIService** (OpenAI API)

```dart
interface AIService {
  // Chat with AI assistant (Lisa)
  Future<String> chat(
    String message,
    {List<Map<String, String>>? history}
  );

  // Detect emotion from text
  Future<String> analyzeEmotion(String text);

  // Generate personalized tasks
  Future<List<Map<String, dynamic>>> generateTasks(
    Map<String, dynamic> analysisData
  );

  // Perform weekly analysis
  Future<Map<String, dynamic>> weeklyAnalysis(
    Map<String, dynamic> userData
  );
}
```

#### Repository Implementations

Each repository combines data sources:

```dart
class AuthRepositoryImpl implements AuthRepository {
  final SupabaseService supabase;
  final LocalStorageService localStorage;

  @override
  Future<Either<Failure, User>> login({email, password}) async {
    try {
      // 1. Authenticate with Supabase
      final response = await supabase.signInWithEmail(email, password);

      // 2. Convert to model/entity
      final user = UserModel.fromSupabaseUser(response.user);

      // 3. Cache locally
      await localStorage.saveString('user_id', user.id);
      await localStorage.saveBool('is_logged_in', true);

      // 4. Return success
      return Right(user);
    } catch (e) {
      // 5. Handle errors
      return Left(AuthFailure(e.toString()));
    }
  }
}

// Similar pattern for all repositories
ChatRepositoryImpl
├── Dependencies: SupabaseService, LocalStorageService, AIService
└── Implements: ChatRepository

JournalRepositoryImpl
├── Dependencies: SupabaseService
└── Implements: JournalRepository

TaskRepositoryImpl
├── Dependencies: SupabaseService, LocalStorageService, AIService
└── Implements: TaskRepository

GameRepositoryImpl
├── Dependencies: SupabaseService, LocalStorageService
└── Implements: GameRepository
```

### 4. Core Layer

#### Responsibilities

- Share utilities across layers
- Define app-wide constants
- Define error types
- Configure themes

#### Components

**Constants**

```dart
ApiConstants
├── supabaseUrl
├── supabaseAnonKey
├── aiApiUrl
├── aiApiKey
└── aiModel

AppConstants
├── maxDailyTasks
├── weeklyAnalysisDays
├── petHappinessDecay
└── storageKeys

GameConstants
├── roomWidth, roomHeight
├── playerSpeed
├── interactionDistance
├── objectPositions
└── emotionColors

AIPrompts
├── lisaSystemPrompt
├── emotionAnalysisPrompt
├── weeklyAnalysisPrompt
└── taskGenerationPrompt
```

**Errors**

```dart
Failure (Domain errors)
├── ServerFailure
├── CacheFailure
├── NetworkFailure
├── AuthFailure
├── DataParsingFailure
└── AIServiceFailure

Exception (Data errors)
├── ServerException
├── CacheException
├── NetworkException
├── AuthException
└── AIException
```

**Theme**

```dart
AppTheme
├── lightTheme
├── darkTheme
└── emotionColors
    ├── calm: blue
    ├── happy: yellow
    ├── sad: gray-blue
    ├── angry: red
    └── anxious: purple
```

**Utils**

```dart
DateFormatter
├── formatDate()
├── formatDateTime()
├── formatRelativeTime()
└── daysSince()

Validators
├── validateEmail()
├── validatePassword()
├── validateRequired()
└── validateMoodScale()

StringUtils
├── truncate()
├── capitalize()
├── generateRandomString()
└── cleanForAI()
```

## Data Flow Examples

### Example 1: User Sends Chat Message

```
User types message
    ↓
ChatScreen → ChatBloc.add(SendMessageEvent)
    ↓
ChatBloc → SendMessageUseCase.call(message)
    ↓
SendMessageUseCase → ChatRepository.sendMessage()
    ↓
ChatRepositoryImpl:
  1. AIService.analyzeEmotion(message) → "anxious"
  2. AIService.chat(message) → "response from Lisa"
  3. SupabaseService.insert('chat_messages', userMessage)
  4. SupabaseService.insert('chat_messages', assistantMessage)
  5. Return List<ChatMessage>
    ↓
ChatBloc.emit(ChatLoaded(messages))
    ↓
ChatScreen rebuilds with new messages
```

### Example 2: Weekly Analysis

```
Cron job triggers (every 7 days)
    ↓
TaskBloc → WeeklyAnalysisUseCase.call(userId)
    ↓
WeeklyAnalysisUseCase → TaskRepository.performWeeklyAnalysis()
    ↓
TaskRepositoryImpl:
  1. Fetch data from Supabase:
     - ChatRepository.getChatHistory() → messages
     - JournalRepository.getEntries() → entries
     - TaskRepository.getTasks() → tasks
     - GameRepository.getRoomState() → interactions
  2. Build analysis data object
  3. AIService.weeklyAnalysis(data) → JSON response
  4. Parse JSON → WeeklyAnalysis entity
  5. Extract personalizedTasks
  6. Generate new tasks:
     AIService.generateTasks(personalizedTasks) → tasks
  7. TaskRepository.createTasks(tasks)
  8. Return WeeklyAnalysis
    ↓
TaskBloc.emit(AnalysisComplete(analysis))
    ↓
Show notification to user with insights
```

### Example 3: Game Object Interaction

```
User taps Pet object in game
    ↓
SafeRoomGame.onObjectInteraction('pet')
    ↓
GameScreen → GameBloc.add(InteractWithObject('pet'))
    ↓
GameBloc → GameRepository.recordInteraction('pet')
    ↓
GameRepositoryImpl:
  1. Get current RoomState from local cache
  2. Increment interactionCounts['pet']
  3. Increase petHappiness (+10)
  4. Update RoomState locally
  5. SupabaseService.update('game_state', updatedState)
  6. Return updated RoomState
    ↓
GameBloc.emit(GameLoaded(newRoomState))
    ↓
MentalStateEngine.updateRoomState(newRoomState)
    ↓
PetObject shows happy animation
```

## Dependency Injection

Using GetIt service locator:

```dart
final sl = GetIt.instance;

Future<void> init() async {
  // External
  sl.registerLazySingleton(() => http.Client());
  sl.registerLazySingleton(() => SharedPreferences.getInstance());
  sl.registerLazySingleton(() => Supabase.instance.client);

  // Data Sources
  sl.registerLazySingleton<LocalStorageService>(
    () => LocalStorageServiceImpl(sl())
  );
  sl.registerLazySingleton<SupabaseService>(
    () => SupabaseServiceImpl(sl())
  );
  sl.registerLazySingleton<AIService>(
    () => AIServiceImpl(sl())
  );

  // Repositories
  sl.registerLazySingleton<AuthRepository>(
    () => AuthRepositoryImpl(sl(), sl())
  );
  // ... other repositories

  // Use Cases
  sl.registerLazySingleton(() => LoginUseCase(sl()));
  // ... other use cases

  // BLoCs (Factory = new instance each time)
  sl.registerFactory(() => AuthBloc(
    loginUseCase: sl(),
    registerUseCase: sl(),
    logoutUseCase: sl(),
  ));
  // ... other blocs
}
```

## State Management Flow

Using BLoC pattern:

```dart
// 1. Define Events
abstract class ChatEvent {}
class SendMessage extends ChatEvent {
  final String message;
}

// 2. Define States
abstract class ChatState {}
class ChatInitial extends ChatState {}
class ChatLoading extends ChatState {}
class ChatLoaded extends ChatState {
  final List<ChatMessage> messages;
}
class ChatError extends ChatState {
  final String message;
}

// 3. Implement BLoC
class ChatBloc extends Bloc<ChatEvent, ChatState> {
  final SendMessageUseCase sendMessageUseCase;

  ChatBloc({required this.sendMessageUseCase}) : super(ChatInitial()) {
    on<SendMessage>(_onSendMessage);
  }

  Future<void> _onSendMessage(
    SendMessage event,
    Emitter<ChatState> emit,
  ) async {
    emit(ChatLoading());

    final result = await sendMessageUseCase(event.message);

    result.fold(
      (failure) => emit(ChatError(failure.message)),
      (messages) => emit(ChatLoaded(messages)),
    );
  }
}

// 4. Use in UI
BlocBuilder<ChatBloc, ChatState>(
  builder: (context, state) {
    if (state is ChatLoading) return LoadingIndicator();
    if (state is ChatError) return ErrorWidget(state.message);
    if (state is ChatLoaded) return MessageList(state.messages);
    return Container();
  },
)
```

## Error Handling Strategy

```dart
// Use Either type from dartz package
// Left = Failure, Right = Success

Future<Either<Failure, User>> login() async {
  try {
    // Attempt operation
    final result = await supabase.signIn();
    return Right(result);
  } on NetworkException {
    return Left(NetworkFailure());
  } on AuthException catch (e) {
    return Left(AuthFailure(e.message));
  } catch (e) {
    return Left(ServerFailure(e.toString()));
  }
}

// In BLoC:
result.fold(
  (failure) {
    // Handle error
    emit(ErrorState(failure.message));
  },
  (data) {
    // Handle success
    emit(LoadedState(data));
  },
);
```

## Security Considerations

### Authentication

- Email/password via Supabase Auth
- Anonymous login supported
- JWT tokens managed by Supabase SDK
- Auto-refresh tokens

### Data Access

- Row-Level Security (RLS) on all tables
- Users can only access their own data
- Policies: `auth.uid() = user_id`

### API Keys

- Never commit keys to version control
- Use environment variables
- Rotate keys regularly
- Monitor usage

### Data Privacy

- No medical data stored
- Emotional data encrypted at rest
- GDPR-compliant data deletion
- Clear privacy policy

## Performance Optimization

### Caching Strategy

```dart
// 1. Check local cache first
final cached = await localStorage.getRoomState();
if (cached != null && !isStale(cached)) {
  return cached;
}

// 2. Fetch from server if cache miss or stale
final remote = await supabase.getRoomState();

// 3. Update cache
await localStorage.saveRoomState(remote);

return remote;
```

### Lazy Loading

- BLoCs created only when needed (Factory pattern)
- Images loaded on demand
- Paginate journal entries and chat history

### Game Optimization

- Use Flame's built-in optimization
- Limit particle effects
- Reuse components
- Update only when state changes

## Testing Strategy

### Unit Tests

```dart
// Domain layer (business logic)
test('LoginUseCase returns user on success', () async {
  // Arrange
  final mockRepo = MockAuthRepository();
  final useCase = LoginUseCase(mockRepo);

  when(mockRepo.login(any, any)).thenAnswer(
    (_) async => Right(testUser)
  );

  // Act
  final result = await useCase('test@test.com', 'password');

  // Assert
  expect(result, Right(testUser));
});
```

### Widget Tests

```dart
testWidgets('ChatScreen displays messages', (tester) async {
  await tester.pumpWidget(
    BlocProvider(
      create: (_) => mockChatBloc,
      child: ChatScreen(),
    ),
  );

  expect(find.byType(MessageBubble), findsNWidgets(2));
});
```

### Integration Tests

```dart
testWidgets('Complete user flow', (tester) async {
  // Login
  await tester.tap(find.text('Login'));
  await tester.pumpAndSettle();

  // Navigate to chat
  await tester.tap(find.byIcon(Icons.chat));
  await tester.pumpAndSettle();

  // Send message
  await tester.enterText(find.byType(TextField), 'Hello');
  await tester.tap(find.byIcon(Icons.send));
  await tester.pumpAndSettle();

  // Verify response
  expect(find.text('Hello'), findsOneWidget);
});
```

## Deployment Pipeline

```
1. Development
   └── Local testing with mock data

2. Staging
   ├── Deploy to test environment
   ├── Run automated tests
   └── Manual QA testing

3. Production
   ├── Build release APK/IPA
   ├── Upload to Play Store / App Store
   └── Monitor with analytics

4. Monitoring
   ├── Error tracking (Sentry)
   ├── Analytics (Firebase)
   └── Performance monitoring
```

## Future Enhancements

### Planned Features

- [ ] Voice journal entries (speech-to-text)
- [ ] Guided meditation timer
- [ ] Wearable device sync (heart rate, sleep)
- [ ] Social features (anonymous sharing)
- [ ] Multiple themed rooms
- [ ] Progressive room customization
- [ ] Therapist portal integration
- [ ] Offline mode with sync

### Technical Improvements

- [ ] GraphQL instead of REST for AI API
- [ ] Background sync with WorkManager
- [ ] Push notifications for task reminders
- [ ] Advanced analytics dashboard
- [ ] A/B testing framework
- [ ] Localization (i18n)
- [ ] Accessibility improvements

---

**Document Version**: 1.0  
**Last Updated**: December 2025  
**Maintained By**: SafeRoom Development Team
