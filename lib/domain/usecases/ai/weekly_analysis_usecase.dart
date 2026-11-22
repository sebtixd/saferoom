import 'package:dartz/dartz.dart';
import '../../../core/errors/failures.dart';
import '../../repositories/chat_repository.dart';
import '../../repositories/journal_repository.dart';
import '../../repositories/task_repository.dart';

/// Use case for weekly AI analysis
class WeeklyAnalysisUseCase {
  final ChatRepository chatRepository;
  final JournalRepository journalRepository;
  final TaskRepository taskRepository;

  WeeklyAnalysisUseCase(this.chatRepository, {
    JournalRepository? journalRepo,
    TaskRepository? taskRepo,
  })  : journalRepository = journalRepo ?? _DummyJournalRepository(),
        taskRepository = taskRepo ?? _DummyTaskRepository();

  /// Analyze user data from the past week
  Future<Either<Failure, Map<String, dynamic>>> call(String userId) async {
    try {
      final now = DateTime.now();
      final weekAgo = now.subtract(const Duration(days: 7));

      // Get chat history for the week
      final chatResult = await chatRepository.getChatHistoryByDateRange(
        userId: userId,
        startDate: weekAgo,
        endDate: now,
      );

      // Get journal entries for the week
      final journalResult = await journalRepository.getEntriesByDateRange(
        userId: userId,
        startDate: weekAgo,
        endDate: now,
      );

      // Get tasks for the week
      // Get tasks for the week (Stubbed - repo doesn't support date range yet)
      // final tasksResult = await taskRepository.getTasksByDate(
      //   userId: userId,
      //   date: now,
      // );
      final tasksResult = const Right([]); // Empty list for now

      // Compile analysis data
      final analysisData = <String, dynamic>{
        'chatMessages': chatResult.fold((l) => [], (r) => r),
        'journalEntries': journalResult.fold((l) => [], (r) => r),
        'tasks': tasksResult.fold((l) => [], (r) => r),
        'analysisDate': now.toIso8601String(),
        'periodStart': weekAgo.toIso8601String(),
        'periodEnd': now.toIso8601String(),
      };

      return Right(analysisData);
    } catch (e) {
      return const Left(ServerFailure(message: 'Failed to compile weekly analysis'));
    }
  }
}

// Dummy implementations for dependency injection
class _DummyJournalRepository implements JournalRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError();
}

class _DummyTaskRepository implements TaskRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError();
}
