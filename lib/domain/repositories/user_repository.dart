import 'package:dartz/dartz.dart';
import '../../core/errors/failures.dart';
import '../entities/user.dart';
import '../entities/emotional_profile.dart';

/// Repository interface for user operations
abstract class UserRepository {
  /// Get user by ID
  Future<Either<Failure, User>> getUserById(String userId);

  /// Update user profile
  Future<Either<Failure, User>> updateUser(User user);

  /// Save emotional profile
  Future<Either<Failure, EmotionalProfile>> saveEmotionalProfile(
    EmotionalProfile profile,
  );

  /// Get emotional profile by user ID
  Future<Either<Failure, EmotionalProfile?>> getEmotionalProfile(String userId);

  /// Update emotional profile
  Future<Either<Failure, EmotionalProfile>> updateEmotionalProfile(
    EmotionalProfile profile,
  );

  /// Check if user has completed onboarding
  Future<bool> hasCompletedOnboarding(String userId);
}
