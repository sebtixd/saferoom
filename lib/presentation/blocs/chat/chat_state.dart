import 'package:equatable/equatable.dart';
import '../../../domain/entities/chat_message.dart';

/// Chat states
abstract class ChatState extends Equatable {
  const ChatState();

  @override
  List<Object?> get props => [];
}

/// Initial state
class ChatInitial extends ChatState {
  const ChatInitial();
}

/// Loading state
class ChatLoading extends ChatState {
  const ChatLoading();
}

/// Loaded state
class ChatLoaded extends ChatState {
  final List<ChatMessage> messages;
  final bool isSending;

  const ChatLoaded({
    required this.messages,
    this.isSending = false,
  });

  ChatLoaded copyWith({
    List<ChatMessage>? messages,
    bool? isSending,
  }) {
    return ChatLoaded(
      messages: messages ?? this.messages,
      isSending: isSending ?? this.isSending,
    );
  }

  @override
  List<Object?> get props => [messages, isSending];
}

/// Error state
class ChatError extends ChatState {
  final String message;
  final List<ChatMessage> messages;

  const ChatError({
    required this.message,
    this.messages = const [],
  });

  @override
  List<Object?> get props => [message, messages];
}
