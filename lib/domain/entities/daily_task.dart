import 'package:equatable/equatable.dart';

/// Represents a single task within daily tasks
class TaskItem extends Equatable {
  final String text;
  final bool completed;

  const TaskItem({
    required this.text,
    this.completed = false,
  });

  TaskItem copyWith({
    String? text,
    bool? completed,
  }) {
    return TaskItem(
      text: text ?? this.text,
      completed: completed ?? this.completed,
    );
  }

  @override
  List<Object?> get props => [text, completed];
}

/// Represents daily tasks for a user
class DailyTask extends Equatable {
  final String id;
  final String userId;
  final DateTime date;
  final List<TaskItem> tasks;
  final DateTime createdAt;
  final DateTime updatedAt;

  const DailyTask({
    required this.id,
    required this.userId,
    required this.date,
    required this.tasks,
    required this.createdAt,
    required this.updatedAt,
  });

  DailyTask copyWith({
    String? id,
    String? userId,
    DateTime? date,
    List<TaskItem>? tasks,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return DailyTask(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      date: date ?? this.date,
      tasks: tasks ?? this.tasks,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [id, userId, date, tasks, createdAt, updatedAt];
}
