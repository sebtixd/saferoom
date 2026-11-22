import 'package:dartz/dartz.dart';
import '../../../core/errors/failures.dart';
import '../../repositories/chat_repository.dart';

/// Use case for analyzing emotion from text
class AnalyzeEmotionUseCase {
  final ChatRepository repository;

  AnalyzeEmotionUseCase(this.repository);

  Future<Either<Failure, String>> call(String text) {
    return repository.analyzeEmotion(text);
  }
}
