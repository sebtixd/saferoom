import 'package:dartz/dartz.dart';
import 'package:uuid/uuid.dart';
import '../../core/constants/api_constants.dart';
import '../../core/errors/exceptions.dart';
import '../../core/errors/failures.dart';
import '../../domain/entities/journal_entry.dart';
import '../../domain/repositories/journal_repository.dart';
import '../datasources/remote/firebase_service.dart';
import '../models/journal_entry_model.dart';

/// Implementation of [JournalRepository]
class JournalRepositoryImpl implements JournalRepository {
  final FirebaseService _firebaseService;

  JournalRepositoryImpl(this._firebaseService);

  @override
  Future<Either<Failure, JournalEntry>> saveEntry(JournalEntry entry) async {
    try {
      final entryWithId = JournalEntryModel(
        id: const Uuid().v4(),
        userId: entry.userId,
        content: entry.content,
        timestamp: DateTime.now(),
        mood: entry.mood,
        tags: entry.tags,
        aiAnalysis: entry.aiAnalysis,
      );

      final data = await _firebaseService.insert(
        ApiConstants.tableJournalEntries,
        entryWithId.toJson(),
      );

      return Right(JournalEntryModel.fromJson(data));
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<JournalEntry>>> getEntries(String userId) async {
    try {
      final data = await _firebaseService.select(
        ApiConstants.tableJournalEntries,
        filters: {'user_id': userId},
      );

      final entries = data
          .map((json) => JournalEntryModel.fromJson(json))
          .toList()
        ..sort((a, b) => b.timestamp.compareTo(a.timestamp));

      return Right(entries);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<JournalEntry>>> getEntriesByDateRange({
    required String userId,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      final allEntries = await getEntries(userId);

      return allEntries.map((entries) => entries
          .where((e) => e.timestamp.isAfter(startDate) && e.timestamp.isBefore(endDate))
          .toList());
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, JournalEntry>> getEntryById(String entryId) async {
    try {
      final data = await _firebaseService.select(
        ApiConstants.tableJournalEntries,
        filters: {'id': entryId},
      );

      if (data.isNotEmpty) {
        return Right(JournalEntryModel.fromJson(data.first));
      }

      return const Left(ServerFailure(message: 'Entry not found'));
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, JournalEntry>> updateEntry(JournalEntry entry) async {
    try {
      final entryModel = JournalEntryModel.fromEntity(entry);
      final data = await _firebaseService.update(
        ApiConstants.tableJournalEntries,
        entry.id,
        entryModel.toJson(),
      );

      return Right(JournalEntryModel.fromJson(data));
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> deleteEntry(String entryId) async {
    try {
      await _firebaseService.delete(ApiConstants.tableJournalEntries, entryId);
      return const Right(null);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, String>> analyzeEntry(String content) async {
    // Simple analysis - in production, this would use AI
    final wordCount = content.split(' ').length;
    final hasPositive = content.toLowerCase().contains(RegExp(r'happy|good|great|wonderful|excited'));
    final hasNegative = content.toLowerCase().contains(RegExp(r'sad|angry|frustrated|anxious|worried'));

    String analysis = 'Your entry contains $wordCount words. ';
    
    if (hasPositive && !hasNegative) {
      analysis += 'It reflects a positive emotional state. Keep nurturing these positive feelings!';
    } else if (hasNegative && !hasPositive) {
      analysis += 'It seems you\'re going through some challenging emotions. Remember, it\'s okay to feel this way.';
    } else if (hasPositive && hasNegative) {
      analysis += 'Your entry shows a mix of emotions, which is completely normal. Take time to reflect on each feeling.';
    } else {
      analysis += 'Keep journaling regularly to track your emotional patterns over time.';
    }

    return Right(analysis);
  }
}
