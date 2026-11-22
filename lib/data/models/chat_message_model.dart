import '../../domain/entities/chat_message.dart';

/// Data model for ChatMessage entity
class ChatMessageModel extends ChatMessage {
  const ChatMessageModel({
    required super.id,
    required super.userId,
    required super.content,
    required super.isUser,
    required super.timestamp,
    super.emotionDetected,
    super.topic,
  });

  factory ChatMessageModel.fromJson(Map<String, dynamic> json) {
    return ChatMessageModel(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      content: json['content'] as String,
      isUser: json['is_user'] as bool,
      timestamp: DateTime.parse(json['timestamp'] as String),
      emotionDetected: json['emotion_detected'] as String?,
      topic: json['topic'] as String?,
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'content': content,
      'is_user': isUser,
      'timestamp': timestamp.toIso8601String(),
      'emotion_detected': emotionDetected,
      'topic': topic,
    };
  }

  factory ChatMessageModel.fromEntity(ChatMessage message) {
    return ChatMessageModel(
      id: message.id,
      userId: message.userId,
      content: message.content,
      isUser: message.isUser,
      timestamp: message.timestamp,
      emotionDetected: message.emotionDetected,
      topic: message.topic,
    );
  }
}
