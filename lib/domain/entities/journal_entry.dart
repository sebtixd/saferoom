import 'package:equatable/equatable.dart';

/// Journal entry entity for user journaling
class JournalEntry extends Equatable {
  final String id;
  final String userId;
  final String content;
  final DateTime timestamp;
  final String? mood;
  final List<String>? tags;
  final String? aiAnalysis;

  const JournalEntry({
    required this.id,
    required this.userId,
    required this.content,
    required this.timestamp,
    this.mood,
    this.tags,
    this.aiAnalysis,
  });

  /// Create a copy with updated fields
  JournalEntry copyWith({
    String? id,
    String? userId,
    String? content,
    DateTime? timestamp,
    String? mood,
    List<String>? tags,
    String? aiAnalysis,
  }) {
    return JournalEntry(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      content: content ?? this.content,
      timestamp: timestamp ?? this.timestamp,
      mood: mood ?? this.mood,
      tags: tags ?? this.tags,
      aiAnalysis: aiAnalysis ?? this.aiAnalysis,
    );
  }

  @override
  List<Object?> get props => [
        id,
        userId,
        content,
        timestamp,
        mood,
        tags,
        aiAnalysis,
      ];
}
