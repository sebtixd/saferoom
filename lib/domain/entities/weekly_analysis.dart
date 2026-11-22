import 'package:equatable/equatable.dart';

class WeeklyAnalysis extends Equatable {
  final String id;
  final String userId;
  final DateTime weekStartDate;
  final DateTime weekEndDate;
  final EmotionalTrends emotionalTrends;
  final List<Pattern> patterns;
  final List<String> strengths;
  final List<String> recommendations;
  final List<PersonalizedTask> personalizedTasks;
  final AnalysisMetrics metrics;
  final DateTime createdAt;

  const WeeklyAnalysis({
    required this.id,
    required this.userId,
    required this.weekStartDate,
    required this.weekEndDate,
    required this.emotionalTrends,
    required this.patterns,
    required this.strengths,
    required this.recommendations,
    required this.personalizedTasks,
    required this.metrics,
    required this.createdAt,
  });

  @override
  List<Object?> get props => [
    id,
    userId,
    weekStartDate,
    weekEndDate,
    emotionalTrends,
    patterns,
    strengths,
    recommendations,
    personalizedTasks,
    metrics,
    createdAt,
  ];
}

class EmotionalTrends extends Equatable {
  final List<String> dominantEmotions;
  final String emotionalPattern;
  final Map<String, int>? emotionFrequency; // Optional: count of each emotion

  const EmotionalTrends({
    required this.dominantEmotions,
    required this.emotionalPattern,
    this.emotionFrequency,
  });

  @override
  List<Object?> get props => [
    dominantEmotions,
    emotionalPattern,
    emotionFrequency,
  ];
}

class Pattern extends Equatable {
  final String pattern;
  final String? trigger;
  final String recommendation;

  const Pattern({
    required this.pattern,
    this.trigger,
    required this.recommendation,
  });

  @override
  List<Object?> get props => [pattern, trigger, recommendation];
}

class PersonalizedTask extends Equatable {
  final String task;
  final String reason;
  final String? category;

  const PersonalizedTask({
    required this.task,
    required this.reason,
    this.category,
  });

  @override
  List<Object?> get props => [task, reason, category];
}

class AnalysisMetrics extends Equatable {
  final int totalChatMessages;
  final int totalJournalEntries;
  final int tasksCompleted;
  final int totalTasks;
  final Map<String, int> interactionCounts;
  final double taskCompletionRate;

  const AnalysisMetrics({
    required this.totalChatMessages,
    required this.totalJournalEntries,
    required this.tasksCompleted,
    required this.totalTasks,
    required this.interactionCounts,
    required this.taskCompletionRate,
  });

  @override
  List<Object?> get props => [
    totalChatMessages,
    totalJournalEntries,
    tasksCompleted,
    totalTasks,
    interactionCounts,
    taskCompletionRate,
  ];
}
