import 'package:dartz/dartz.dart';
import '../../../core/errors/failures.dart';
import '../../entities/chat_message.dart';
import '../../repositories/chat_repository.dart';

/// Use case for getting chat history
class GetChatHistoryUseCase {
  final ChatRepository repository;

  GetChatHistoryUseCase(this.repository);

  Future<Either<Failure, List<ChatMessage>>> call(String userId) {
    return repository.getChatHistory(userId);
  }
}
