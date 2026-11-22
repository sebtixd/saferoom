import 'package:equatable/equatable.dart';

/// Chat message entity for AI assistant conversations
class ChatMessage extends Equatable {
  final String id;
  final String userId;
  final String content;
  final bool isUser;
  final DateTime timestamp;
  final String? emotionDetected;
  final String? topic;

  const ChatMessage({
    required this.id,
    required this.userId,
    required this.content,
    required this.isUser,
    required this.timestamp,
    this.emotionDetected,
    this.topic,
  });

  /// Convert to JSON for storage (matching required format)
  Map<String, dynamic> toJson() {
    return {
      'timestamp': timestamp.toIso8601String(),
      'emotionDetected': emotionDetected ?? '',
      'topic': topic ?? '',
    };
  }

  /// Create a copy with updated fields
  ChatMessage copyWith({
    String? id,
    String? userId,
    String? content,
    bool? isUser,
    DateTime? timestamp,
    String? emotionDetected,
    String? topic,
  }) {
    return ChatMessage(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      content: content ?? this.content,
      isUser: isUser ?? this.isUser,
      timestamp: timestamp ?? this.timestamp,
      emotionDetected: emotionDetected ?? this.emotionDetected,
      topic: topic ?? this.topic,
    );
  }

  @override
  List<Object?> get props => [
        id,
        userId,
        content,
        isUser,
        timestamp,
        emotionDetected,
        topic,
      ];
}
