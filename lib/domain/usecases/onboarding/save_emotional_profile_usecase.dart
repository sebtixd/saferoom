import 'package:dartz/dartz.dart';
import '../../../core/errors/failures.dart';
import '../../entities/emotional_profile.dart';
import '../../repositories/user_repository.dart';

/// Use case for saving emotional profile during onboarding
class SaveEmotionalProfileUseCase {
  final UserRepository repository;

  SaveEmotionalProfileUseCase(this.repository);

  Future<Either<Failure, EmotionalProfile>> call(EmotionalProfile profile) {
    return repository.saveEmotionalProfile(profile);
  }
}
