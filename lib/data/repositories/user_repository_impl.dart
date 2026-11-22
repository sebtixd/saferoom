import 'package:dartz/dartz.dart';
import 'package:uuid/uuid.dart';

import '../../core/errors/exceptions.dart';
import '../../core/errors/failures.dart';
import '../../domain/entities/emotional_profile.dart';
import '../../domain/entities/user.dart';
import '../../domain/repositories/user_repository.dart';
import '../datasources/local/local_storage_service.dart';
import '../datasources/local/token_storage.dart';
import '../datasources/remote/auth_api_service.dart';

/// User data backed by the SafeRoom API (no direct database access from the app).
class UserRepositoryImpl implements UserRepository {
  final AuthApiService _api;
  final TokenStorage _tokenStorage;
  final LocalStorageService _localStorage;

  UserRepositoryImpl(this._api, this._tokenStorage, this._localStorage);

  @override
  Future<Either<Failure, User>> getUserById(String userId) async {
    try {
      final user = await _api.getUser(
        id: userId,
        accessToken: await _accessToken(),
      );
      return Right(user);
    } on AppException catch (e) {
      return Left(_toFailure(e));
    }
  }

  @override
  Future<Either<Failure, User>> updateUser(User user) async {
    try {
      final updated = await _api.updatePoints(
        id: user.id,
        points: user.points,
        accessToken: await _accessToken(),
      );
      return Right(user.copyWith(points: updated.points));
    } on AppException catch (e) {
      return Left(_toFailure(e));
    }
  }

  @override
  Future<Either<Failure, EmotionalProfile>> saveEmotionalProfile(
    EmotionalProfile profile,
  ) async {
    try {
      final now = DateTime.now();
      final profileWithId = EmotionalProfileModel(
        id: const Uuid().v4(),
        oduyId: profile.oduyId,
        moodBaseline: profile.moodBaseline,
        stressLevel: profile.stressLevel,
        energyLevel: profile.energyLevel,
        happinessTriggers: profile.happinessTriggers,
        angerTriggers: profile.angerTriggers,
        calmingFactors: profile.calmingFactors,
        preferredColor: profile.preferredColor,
        spiritualPreference: profile.spiritualPreference,
        workRhythm: profile.workRhythm,
        createdAt: now,
        updatedAt: now,
      );

      final saved = await _api.saveEmotionalProfile(
        profile: profileWithId,
        accessToken: await _accessToken(),
      );
      await _localStorage.saveBool('onboarding_complete', true);
      return Right(saved);
    } on AppException catch (e) {
      return Left(_toFailure(e));
    }
  }

  @override
  Future<Either<Failure, EmotionalProfile?>> getEmotionalProfile(
    String userId,
  ) async {
    try {
      final user = await _api.getCurrentUser(accessToken: await _accessToken());
      return Right(user.emotionalProfile);
    } on AppException catch (e) {
      return Left(_toFailure(e));
    }
  }

  @override
  Future<Either<Failure, EmotionalProfile>> updateEmotionalProfile(
    EmotionalProfile profile,
  ) async {
    try {
      final updated = await _api.saveEmotionalProfile(
        profile: profile,
        accessToken: await _accessToken(),
      );
      return Right(updated);
    } on AppException catch (e) {
      return Left(_toFailure(e));
    }
  }

  @override
  Future<bool> hasCompletedOnboarding(String userId) async {
    final localResult = await _localStorage.getBool('onboarding_complete');
    if (localResult == true) return true;

    final result = await getEmotionalProfile(userId);
    return result.fold(
      (failure) => false,
      (profile) {
        if (profile != null) {
          _localStorage.saveBool('onboarding_complete', true);
          return true;
        }
        return false;
      },
    );
  }

  Future<String> _accessToken() async {
    final token = await _tokenStorage.readAccessToken();
    if (token == null || token.isEmpty) {
      throw const AuthException(message: 'Not authenticated', code: 'invalid_token');
    }
    return token;
  }

  Failure _toFailure(AppException exception) {
    if (exception is NetworkException) {
      return NetworkFailure(message: exception.message, code: exception.code);
    }
    if (exception is ValidationException) {
      return ValidationFailure(message: exception.message, code: exception.code);
    }
    if (exception is AuthException) {
      return AuthFailure(message: exception.message, code: exception.code);
    }
    if (exception is ServerException) {
      return ServerFailure(message: exception.message, code: exception.code);
    }
    return UnknownFailure(message: exception.message, code: exception.code);
  }
}

/// EmotionalProfile model for repository serialization.
class EmotionalProfileModel extends EmotionalProfile {
  const EmotionalProfileModel({
    required super.id,
    required super.oduyId,
    required super.moodBaseline,
    required super.stressLevel,
    required super.energyLevel,
    required super.happinessTriggers,
    required super.angerTriggers,
    required super.calmingFactors,
    required super.preferredColor,
    super.spiritualPreference,
    required super.workRhythm,
    required super.createdAt,
    required super.updatedAt,
  });

  factory EmotionalProfileModel.fromJson(Map<String, dynamic> json) {
    return EmotionalProfileModel(
      id: json['id'] as String,
      oduyId: json['user_id'] as String,
      moodBaseline: json['mood_baseline'] as int,
      stressLevel: json['stress_level'] as int,
      energyLevel: json['energy_level'] as int,
      happinessTriggers:
          List<String>.from(json['happiness_triggers'] as List? ?? []),
      angerTriggers: List<String>.from(json['anger_triggers'] as List? ?? []),
      calmingFactors: List<String>.from(json['calming_factors'] as List? ?? []),
      preferredColor: json['preferred_color'] as String? ?? '#6B5CE7',
      spiritualPreference: json['spiritual_preference'] as String?,
      workRhythm: json['work_rhythm'] as String? ?? 'regular',
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': oduyId,
      'mood_baseline': moodBaseline,
      'stress_level': stressLevel,
      'energy_level': energyLevel,
      'happiness_triggers': happinessTriggers,
      'anger_triggers': angerTriggers,
      'calming_factors': calmingFactors,
      'preferred_color': preferredColor,
      'spiritual_preference': spiritualPreference,
      'work_rhythm': workRhythm,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory EmotionalProfileModel.fromEntity(EmotionalProfile profile) {
    return EmotionalProfileModel(
      id: profile.id,
      oduyId: profile.oduyId,
      moodBaseline: profile.moodBaseline,
      stressLevel: profile.stressLevel,
      energyLevel: profile.energyLevel,
      happinessTriggers: profile.happinessTriggers,
      angerTriggers: profile.angerTriggers,
      calmingFactors: profile.calmingFactors,
      preferredColor: profile.preferredColor,
      spiritualPreference: profile.spiritualPreference,
      workRhythm: profile.workRhythm,
      createdAt: profile.createdAt,
      updatedAt: profile.updatedAt,
    );
  }
}
