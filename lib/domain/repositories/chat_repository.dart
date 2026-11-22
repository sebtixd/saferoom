import 'package:dartz/dartz.dart';
import '../../core/errors/failures.dart';
import '../entities/chat_message.dart';

/// Repository interface for chat operations with AI assistant
abstract class ChatRepository {
  /// Send message to AI assistant
  Future<Either<Failure, ChatMessage>> sendMessage({
    required String userId,
    required String content,
  });

  /// Get chat history for user
  Future<Either<Failure, List<ChatMessage>>> getChatHistory(String userId);

  /// Get chat history by date range
  Future<Either<Failure, List<ChatMessage>>> getChatHistoryByDateRange({
    required String userId,
    required DateTime startDate,
    required DateTime endDate,
  });

  /// Analyze emotion from text
  Future<Either<Failure, String>> analyzeEmotion(String text);

  /// Delete chat message
  Future<Either<Failure, void>> deleteMessage(String messageId);

  /// Clear all chat history for user
  Future<Either<Failure, void>> clearChatHistory(String userId);
}
