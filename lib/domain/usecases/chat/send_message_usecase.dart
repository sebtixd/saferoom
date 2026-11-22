import 'package:dartz/dartz.dart';
import '../../../core/errors/failures.dart';
import '../../entities/chat_message.dart';
import '../../repositories/chat_repository.dart';

/// Use case for sending message to AI assistant
class SendMessageUseCase {
  final ChatRepository repository;

  SendMessageUseCase(this.repository);

  Future<Either<Failure, ChatMessage>> call({
    required String userId,
    required String content,
  }) {
    return repository.sendMessage(userId: userId, content: content);
  }
}
