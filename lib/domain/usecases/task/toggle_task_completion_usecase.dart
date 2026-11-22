import 'package:dartz/dartz.dart';
import '../../../core/errors/failures.dart';
import '../../repositories/task_repository.dart';

class ToggleTaskCompletionUseCase {
  final TaskRepository repository;

  ToggleTaskCompletionUseCase(this.repository);

  Future<Either<Failure, void>> call({
    required String taskId,
    required int taskIndex,
    required bool completed,
  }) {
    return repository.toggleTaskCompletion(taskId, taskIndex, completed);
  }
}
