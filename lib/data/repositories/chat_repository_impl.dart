import 'package:dartz/dartz.dart';
import 'package:uuid/uuid.dart';
import '../../core/constants/api_constants.dart';
import '../../core/errors/exceptions.dart';
import '../../core/errors/failures.dart';
import '../../domain/entities/chat_message.dart';
import '../../domain/repositories/chat_repository.dart';
import '../datasources/remote/firebase_service.dart';
import '../datasources/remote/ai_service.dart';
import '../models/chat_message_model.dart';

/// Implementation of [ChatRepository]
class ChatRepositoryImpl implements ChatRepository {
  final FirebaseService _firebaseService;
  final AIService _aiService;

  ChatRepositoryImpl(this._firebaseService, this._aiService);

  @override
  Future<Either<Failure, ChatMessage>> sendMessage({
    required String userId,
    required String content,
  }) async {
    try {
      // Save user message
      final userMessage = ChatMessageModel(
        id: const Uuid().v4(),
        userId: userId,
        content: content,
        isUser: true,
        timestamp: DateTime.now(),
      );
      
      await _firebaseService.insert(
        ApiConstants.tableChatMessages,
        userMessage.toJson(),
      );

      // Get chat history for context
      final historyResult = await getChatHistory(userId);
      final history = historyResult.fold(
        (failure) => <ChatMessage>[],
        (messages) => messages.take(10).toList(),
      );

      // Convert to AI format
      final aiHistory = history.map((m) => {
        'role': m.isUser ? 'user' : 'assistant',
        'content': m.content,
      }).toList();

      // Get AI response
      final aiResponse = await _aiService.chat(content, history: aiHistory);
      
      // Analyze emotion
      final emotion = await _aiService.analyzeEmotion(content);

      // Save AI response
      final aiMessage = ChatMessageModel(
        id: const Uuid().v4(),
        userId: userId,
        content: aiResponse,
        isUser: false,
        timestamp: DateTime.now(),
        emotionDetected: emotion,
        topic: _extractTopic(content),
      );

      final savedData = await _firebaseService.insert(
        ApiConstants.tableChatMessages,
        aiMessage.toJson(),
      );

      return Right(ChatMessageModel.fromJson(savedData));
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    } on AIServiceException catch (e) {
      return Left(AIServiceFailure(message: e.message));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<ChatMessage>>> getChatHistory(String userId) async {
    try {
      final data = await _firebaseService.select(
        ApiConstants.tableChatMessages,
        filters: {'user_id': userId},
      );

      final messages = data
          .map((json) => ChatMessageModel.fromJson(json))
          .toList()
        ..sort((a, b) => a.timestamp.compareTo(b.timestamp));

      return Right(messages);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<ChatMessage>>> getChatHistoryByDateRange({
    required String userId,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      // Get all messages and filter by date
      final allMessages = await getChatHistory(userId);
      
      return allMessages.map((messages) => messages
          .where((m) => m.timestamp.isAfter(startDate) && m.timestamp.isBefore(endDate))
          .toList());
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, String>> analyzeEmotion(String text) async {
    try {
      final emotion = await _aiService.analyzeEmotion(text);
      return Right(emotion);
    } on AIServiceException catch (e) {
      return Left(AIServiceFailure(message: e.message));
    } catch (e) {
      return const Right('calm'); // Default on error
    }
  }

  @override
  Future<Either<Failure, void>> deleteMessage(String messageId) async {
    try {
      await _firebaseService.delete(ApiConstants.tableChatMessages, messageId);
      return const Right(null);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }



  @override
  Future<Either<Failure, void>> clearChatHistory(String userId) async {
    try {
      final messagesResult = await getChatHistory(userId);
      return await messagesResult.fold(
        (failure) => Left(failure),
        (messages) async {
          for (var message in messages) {
            await _firebaseService.delete(ApiConstants.tableChatMessages, message.id);
          }
          return const Right(null);
        },
      );
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  String _extractTopic(String content) {
    // Simple topic extraction based on keywords
    final lowerContent = content.toLowerCase();
    
    if (lowerContent.contains('work') || lowerContent.contains('job') || lowerContent.contains('office')) {
      return 'work';
    } else if (lowerContent.contains('family') || lowerContent.contains('parent') || lowerContent.contains('child')) {
      return 'family';
    } else if (lowerContent.contains('friend') || lowerContent.contains('relationship')) {
      return 'relationships';
    } else if (lowerContent.contains('stress') || lowerContent.contains('anxious') || lowerContent.contains('worried')) {
      return 'stress';
    } else if (lowerContent.contains('happy') || lowerContent.contains('good') || lowerContent.contains('great')) {
      return 'positive';
    } else if (lowerContent.contains('sad') || lowerContent.contains('down') || lowerContent.contains('depressed')) {
      return 'mood';
    }
    
    return 'general';
  }
}
