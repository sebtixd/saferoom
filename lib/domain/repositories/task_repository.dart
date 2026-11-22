import 'package:dartz/dartz.dart';
import '../../core/errors/failures.dart';
import '../entities/daily_task.dart';

/// Repository interface for daily tasks
abstract class TaskRepository {
  /// Get today's tasks for a user
  /// Returns existing tasks if they exist, otherwise generates new ones
  Future<Either<Failure, DailyTask>> getTodaysTasks(String userId);
  
  /// Generate new daily tasks based on emotional profile
  Future<Either<Failure, DailyTask>> generateDailyTasks(String userId);
  
  /// Mark a specific task as completed or uncompleted
  Future<Either<Failure, void>> toggleTaskCompletion(
    String taskId,
    int taskIndex,
    bool completed,
  );
  
  /// Update task completion status
  Future<Either<Failure, DailyTask>> updateDailyTask(DailyTask dailyTask);
}
