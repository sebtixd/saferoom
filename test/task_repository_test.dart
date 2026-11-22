import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:safe_room/core/errors/failures.dart';
import 'package:safe_room/data/datasources/remote/ai_service.dart';
import 'package:safe_room/data/datasources/remote/auth_api_service.dart';
import 'package:safe_room/data/datasources/remote/api_client.dart';
import 'package:safe_room/data/datasources/remote/task_api_service.dart';
import 'package:safe_room/data/repositories/task_repository_impl.dart';
import 'package:safe_room/domain/entities/daily_task.dart';
import 'package:safe_room/domain/entities/journal_entry.dart';
import 'package:safe_room/domain/entities/user.dart';
import 'package:safe_room/domain/entities/emotional_profile.dart';
import 'package:safe_room/domain/repositories/journal_repository.dart';
import 'package:safe_room/domain/repositories/user_repository.dart';

import 'helpers/fakes.dart';
import 'package:safe_room/data/datasources/local/notes_storage.dart';
import 'package:safe_room/domain/entities/note_page.dart';

class FakeTaskApi extends TaskApiService {
  DailyTask? stored;
  int saveCount = 0;
  int updateCount = 0;

  FakeTaskApi() : super(ApiClient(), FakeTokenStorage(), AuthApiService());

  @override
  Future<DailyTask?> getDailyTasks({
    required String userId,
    required DateTime date,
  }) async =>
      stored;

  @override
  Future<DailyTask> getDailyTaskById(String id) async => stored!;

  @override
  Future<DailyTask> saveDailyTasks(DailyTask dailyTask) async {
    saveCount++;
    stored = dailyTask;
    return dailyTask;
  }

  @override
  Future<DailyTask> updateDailyTasks(DailyTask dailyTask) async {
    updateCount++;
    stored = dailyTask;
    return dailyTask;
  }
}

class FakeJournalRepository implements JournalRepository {
  @override
  Future<Either<Failure, List<JournalEntry>>> getEntries(String userId) async =>
      Right([]);

  @override
  Future<Either<Failure, JournalEntry>> saveEntry(JournalEntry entry) async =>
      Right(entry);

  @override
  Future<Either<Failure, List<JournalEntry>>> getEntriesByDateRange({
    required String userId,
    required DateTime startDate,
    required DateTime endDate,
  }) async =>
      Right([]);

  @override
  Future<Either<Failure, JournalEntry>> getEntryById(String entryId) async =>
      Left(ServerFailure(message: 'not implemented'));

  @override
  Future<Either<Failure, JournalEntry>> updateEntry(JournalEntry entry) async =>
      Right(entry);

  @override
  Future<Either<Failure, void>> deleteEntry(String entryId) async =>
      const Right(null);

  @override
  Future<Either<Failure, String>> analyzeEntry(String content) async =>
      const Right('');
}

class FakeNotesStorage implements NotesStorage {
  List<NotePage> pages = const [];
  @override
  Future<List<NotePage>> loadPages(String userId) async => pages;
  @override
  Future<void> savePages(String userId, List<NotePage> pages) async {
    this.pages = pages;
  }
}

class FakeAIService implements AIService {
  List<String>? lastNotes;
  @override
  Future<List<String>> generatePersonalizedTasks(List<String> notes) async {
    lastNotes = notes;
    return ['Drink water', 'Take a walk', 'Write one feeling'];
  }

  @override
  Future<String> chat(String message, {List<Map<String, String>>? history}) async =>
      '';

  @override
  Future<String> analyzeEmotion(String text) async => '';

  @override
  Future<List<Map<String, dynamic>>> generateTasks(
    Map<String, dynamic> analysisData,
  ) async =>
      [];

  @override
  Future<Map<String, dynamic>> weeklyAnalysis(
    Map<String, dynamic> userData,
  ) async =>
      {};
}

class FakeUserRepository implements UserRepository {
  @override
  Future<Either<Failure, User>> getUserById(String userId) async =>
      Left(ServerFailure(message: 'unused'));

  @override
  Future<Either<Failure, User>> updateUser(User user) async => Right(user);

  @override
  Future<Either<Failure, EmotionalProfile>> saveEmotionalProfile(
    EmotionalProfile profile,
  ) async =>
      Right(profile);

  @override
  Future<Either<Failure, EmotionalProfile?>> getEmotionalProfile(
    String userId,
  ) async =>
      const Right(null);

  @override
  Future<Either<Failure, EmotionalProfile>> updateEmotionalProfile(
    EmotionalProfile profile,
  ) async =>
      Right(profile);

  @override
  Future<bool> hasCompletedOnboarding(String userId) async => true;
}

DailyTask sampleTask({String id = 'task-1'}) => DailyTask(
      id: id,
      userId: 'user-1',
      date: DateTime(2026, 11, 22),
      tasks: const [
        TaskItem(text: 'Drink water'),
        TaskItem(text: 'Take a walk', completed: true),
      ],
      createdAt: DateTime(2026, 11, 22, 8),
      updatedAt: DateTime(2026, 11, 22, 8),
    );

void main() {
  late FakeTaskApi api;
  late FakeAIService ai;
  late FakeNotesStorage notesStorage;
  late TaskRepositoryImpl repository;

  setUp(() {
    api = FakeTaskApi();
    ai = FakeAIService();
    notesStorage = FakeNotesStorage();
    repository = TaskRepositoryImpl(
      api,
      FakeUserRepository(),
      FakeJournalRepository(),
      ai,
      notesStorage,
    );
  });

  test('getTodaysTasks returns tasks stored by the backend API', () async {
    api.stored = sampleTask();

    final result = await repository.getTodaysTasks('user-1');

    expect(result.isRight(), true);
    result.fold(
      (failure) => fail('Unexpected failure: $failure'),
      (task) => expect(task.id, 'task-1'),
    );
    expect(api.saveCount, 0);
  });

  test('generateDailyTasks persists AI tasks and passes notes context', () async {
    notesStorage.pages = [
      NotePage(
        id: 'n1',
        content: 'I feel stressed about exams',
        title: 'I feel stressed about exams',
        createdAt: DateTime(2026, 11, 22),
        updatedAt: DateTime(2026, 11, 22),
        pageNumber: 1,
      ),
    ];

    final result = await repository.generateDailyTasks('user-1');

    expect(result.isRight(), true);
    expect(api.saveCount, 1);
    expect(api.stored?.tasks.map((t) => t.text).toList(), [
      'Drink water',
      'Take a walk',
      'Write one feeling',
    ]);
    expect(ai.lastNotes, isNotNull);
    expect(ai.lastNotes!.any((n) => n.contains('stressed')), true);
  });

  test('updateDailyTask sends changes to the API', () async {
    final task = sampleTask().copyWith(
      tasks: const [TaskItem(text: 'Drink water', completed: true)],
    );

    final result = await repository.updateDailyTask(task);

    expect(result.isRight(), true);
    expect(api.updateCount, 1);
    expect(api.stored?.tasks.first.completed, true);
  });
}
