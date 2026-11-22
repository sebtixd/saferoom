import 'package:equatable/equatable.dart';
import '../../../domain/entities/daily_task.dart';

abstract class TaskState extends Equatable {
  const TaskState();

  @override
  List<Object?> get props => [];
}

class TaskInitial extends TaskState {}

class TaskLoading extends TaskState {}

class TaskLoaded extends TaskState {
  final DailyTask dailyTask;

  const TaskLoaded(this.dailyTask);

  @override
  List<Object?> get props => [dailyTask];
}

class TaskError extends TaskState {
  final String message;

  const TaskError(this.message);

  @override
  List<Object?> get props => [message];
}
