import 'package:equatable/equatable.dart';

/// Chat events
abstract class ChatEvent extends Equatable {
  const ChatEvent();

  @override
  List<Object?> get props => [];
}

/// Load chat history
class ChatLoadHistory extends ChatEvent {
  final String userId;
  const ChatLoadHistory(this.userId);

  @override
  List<Object?> get props => [userId];
}

/// Send message
class ChatSendMessage extends ChatEvent {
  final String userId;
  final String content;

  const ChatSendMessage({
    required this.userId,
    required this.content,
  });

  @override
  List<Object?> get props => [userId, content];
}

/// Clear chat
class ChatClear extends ChatEvent {
  final String userId;
  const ChatClear(this.userId);

  @override
  List<Object?> get props => [userId];
}
