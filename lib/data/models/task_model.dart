import '../../domain/entities/task.dart';

/// Data model for Task entity
class TaskModel extends Task {
  const TaskModel({
    required super.id,
    required super.userId,
    required super.title,
    required super.description,
    required super.type,
    required super.status,
    required super.createdAt,
    super.completedAt,
    super.impact,
    required super.dayNumber,
  });

  factory TaskModel.fromJson(Map<String, dynamic> json) {
    return TaskModel(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      type: _parseTaskType(json['type'] as String),
      status: _parseTaskStatus(json['status'] as String),
      createdAt: DateTime.parse(json['created_at'] as String),
      completedAt: json['completed_at'] != null
          ? DateTime.parse(json['completed_at'] as String)
          : null,
      impact: json['impact'] as Map<String, dynamic>?,
      dayNumber: json['day_number'] as int? ?? 1,
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'title': title,
      'description': description,
      'type': type == TaskType.generic ? 'generic' : 'personalized',
      'status': _statusToString(status),
      'created_at': createdAt.toIso8601String(),
      'completed_at': completedAt?.toIso8601String(),
      'impact': impact,
      'day_number': dayNumber,
    };
  }

  static TaskType _parseTaskType(String type) {
    switch (type) {
      case 'personalized':
        return TaskType.personalized;
      default:
        return TaskType.generic;
    }
  }

  static TaskStatus _parseTaskStatus(String status) {
    switch (status) {
      case 'in_progress':
        return TaskStatus.inProgress;
      case 'completed':
        return TaskStatus.completed;
      case 'skipped':
        return TaskStatus.skipped;
      default:
        return TaskStatus.pending;
    }
  }

  String _statusToString(TaskStatus status) {
    switch (status) {
      case TaskStatus.pending:
        return 'pending';
      case TaskStatus.inProgress:
        return 'in_progress';
      case TaskStatus.completed:
        return 'completed';
      case TaskStatus.skipped:
        return 'skipped';
    }
  }

  factory TaskModel.fromEntity(Task task) {
    return TaskModel(
      id: task.id,
      userId: task.userId,
      title: task.title,
      description: task.description,
      type: task.type,
      status: task.status,
      createdAt: task.createdAt,
      completedAt: task.completedAt,
      impact: task.impact,
      dayNumber: task.dayNumber,
    );
  }
}
