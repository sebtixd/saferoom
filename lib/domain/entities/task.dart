import 'package:equatable/equatable.dart';

/// Task type enumeration
enum TaskType { generic, personalized }

/// Task status enumeration
enum TaskStatus { pending, inProgress, completed, skipped }

/// Task entity for daily/weekly mental health tasks
class Task extends Equatable {
  final String id;
  final String userId;
  final String title;
  final String description;
  final TaskType type;
  final TaskStatus status;
  final DateTime createdAt;
  final DateTime? completedAt;
  final Map<String, dynamic>? impact;
  final int dayNumber;

  const Task({
    required this.id,
    required this.userId,
    required this.title,
    required this.description,
    required this.type,
    required this.status,
    required this.createdAt,
    this.completedAt,
    this.impact,
    required this.dayNumber,
  });

  /// Check if task is completed
  bool get isCompleted => status == TaskStatus.completed;

  /// Check if task is generic (first 7 days)
  bool get isGeneric => type == TaskType.generic;

  /// Convert to JSON for storage (matching required format)
  Map<String, dynamic> toJson() {
    return {
      'taskId': id,
      'type': type == TaskType.generic ? 'generic' : 'personalized',
      'status': _statusToString(status),
      'impact': impact ?? {},
    };
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

  /// Create a copy with updated fields
  Task copyWith({
    String? id,
    String? userId,
    String? title,
    String? description,
    TaskType? type,
    TaskStatus? status,
    DateTime? createdAt,
    DateTime? completedAt,
    Map<String, dynamic>? impact,
    int? dayNumber,
  }) {
    return Task(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      description: description ?? this.description,
      type: type ?? this.type,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      completedAt: completedAt ?? this.completedAt,
      impact: impact ?? this.impact,
      dayNumber: dayNumber ?? this.dayNumber,
    );
  }

  @override
  List<Object?> get props => [
        id,
        userId,
        title,
        description,
        type,
        status,
        createdAt,
        completedAt,
        impact,
        dayNumber,
      ];
}
