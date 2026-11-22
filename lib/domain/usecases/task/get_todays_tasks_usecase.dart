import 'package:dartz/dartz.dart';
import '../../../core/errors/failures.dart';
import '../../entities/daily_task.dart';
import '../../repositories/task_repository.dart';

class GetTodaysTasksUseCase {
  final TaskRepository repository;

  GetTodaysTasksUseCase(this.repository);

  Future<Either<Failure, DailyTask>> call(String userId) {
    return repository.getTodaysTasks(userId);
  }
}
