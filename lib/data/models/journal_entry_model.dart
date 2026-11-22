import '../../domain/entities/journal_entry.dart';

/// Data model for JournalEntry entity
class JournalEntryModel extends JournalEntry {
  const JournalEntryModel({
    required super.id,
    required super.userId,
    required super.content,
    required super.timestamp,
    super.mood,
    super.tags,
    super.aiAnalysis,
  });

  factory JournalEntryModel.fromJson(Map<String, dynamic> json) {
    return JournalEntryModel(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      content: json['content'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
      mood: json['mood'] as String?,
      tags: json['tags'] != null ? List<String>.from(json['tags'] as List) : null,
      aiAnalysis: json['ai_analysis'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'content': content,
      'timestamp': timestamp.toIso8601String(),
      'mood': mood,
      'tags': tags,
      'ai_analysis': aiAnalysis,
    };
  }

  factory JournalEntryModel.fromEntity(JournalEntry entry) {
    return JournalEntryModel(
      id: entry.id,
      userId: entry.userId,
      content: entry.content,
      timestamp: entry.timestamp,
      mood: entry.mood,
      tags: entry.tags,
      aiAnalysis: entry.aiAnalysis,
    );
  }
}
