import 'package:equatable/equatable.dart';
import 'emotional_profile.dart';

/// User entity representing an authenticated user
class User extends Equatable {
  final String id;
  final String? email;
  final bool isAnonymous;
  final DateTime createdAt;
  final EmotionalProfile? emotionalProfile;
  final int points;

  const User({
    required this.id,
    this.email,
    required this.isAnonymous,
    required this.createdAt,
    this.emotionalProfile,
    this.points = 0,
  });

  /// Check if user has completed onboarding
  bool get hasCompletedOnboarding => emotionalProfile != null;

  /// Create a copy with updated fields
  User copyWith({
    String? id,
    String? email,
    bool? isAnonymous,
    DateTime? createdAt,
    EmotionalProfile? emotionalProfile,
    int? points,
  }) {
    return User(
      id: id ?? this.id,
      email: email ?? this.email,
      isAnonymous: isAnonymous ?? this.isAnonymous,
      createdAt: createdAt ?? this.createdAt,
      emotionalProfile: emotionalProfile ?? this.emotionalProfile,
      points: points ?? this.points,
    );
  }

  @override
  List<Object?> get props => [id, email, isAnonymous, createdAt, emotionalProfile, points];
}
