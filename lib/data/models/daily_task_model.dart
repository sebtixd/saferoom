import '../../domain/entities/daily_task.dart';

/// Adapter for [DailyTask] entity
class DailyTaskModel extends DailyTask {
  const DailyTaskModel({
    required super.id,
    required super.userId,
    required super.date,
    required super.tasks,
    required super.createdAt,
    required super.updatedAt,
  });

  factory DailyTaskModel.fromJson(Map<String, dynamic> json) {
    return DailyTaskModel(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      date: DateTime.parse(json['date'] as String),
      tasks: (json['tasks'] as List<dynamic>)
          .map((e) => TaskItemModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'date': date.toIso8601String().substring(0, 10), // Store as YYYY-MM-DD for simpler querying
      'tasks': tasks.map((e) => (e as TaskItemModel).toJson()).toList(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory DailyTaskModel.fromEntity(DailyTask entity) {
    return DailyTaskModel(
      id: entity.id,
      userId: entity.userId,
      date: entity.date,
      tasks: entity.tasks.map((e) => TaskItemModel.fromEntity(e)).toList(),
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
    );
  }
}

/// Adapter for [TaskItem] entity
class TaskItemModel extends TaskItem {
  const TaskItemModel({
    required super.text,
    super.completed,
  });

  factory TaskItemModel.fromJson(Map<String, dynamic> json) {
    return TaskItemModel(
      text: json['text'] as String,
      completed: json['completed'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'text': text,
      'completed': completed,
    };
  }

  factory TaskItemModel.fromEntity(TaskItem entity) {
    return TaskItemModel(
      text: entity.text,
      completed: entity.completed,
    );
  }
}
