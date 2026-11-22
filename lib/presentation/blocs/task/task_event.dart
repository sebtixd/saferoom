import 'package:equatable/equatable.dart';

abstract class TaskEvent extends Equatable {
  const TaskEvent();

  @override
  List<Object?> get props => [];
}

class LoadDailyTasks extends TaskEvent {
  const LoadDailyTasks();
}

class ToggleTaskCompletion extends TaskEvent {
  final String taskId;
  final int taskIndex;
  final bool completed;

  const ToggleTaskCompletion({
    required this.taskId,
    required this.taskIndex,
    required this.completed,
  });

  @override
  List<Object?> get props => [taskId, taskIndex, completed];
}
