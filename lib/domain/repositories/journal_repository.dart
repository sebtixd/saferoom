import 'package:dartz/dartz.dart';
import '../../core/errors/failures.dart';
import '../entities/journal_entry.dart';

/// Repository interface for journal operations
abstract class JournalRepository {
  /// Save journal entry
  Future<Either<Failure, JournalEntry>> saveEntry(JournalEntry entry);

  /// Get all journal entries for user
  Future<Either<Failure, List<JournalEntry>>> getEntries(String userId);

  /// Get journal entries by date range
  Future<Either<Failure, List<JournalEntry>>> getEntriesByDateRange({
    required String userId,
    required DateTime startDate,
    required DateTime endDate,
  });

  /// Get journal entry by ID
  Future<Either<Failure, JournalEntry>> getEntryById(String entryId);

  /// Update journal entry
  Future<Either<Failure, JournalEntry>> updateEntry(JournalEntry entry);

  /// Delete journal entry
  Future<Either<Failure, void>> deleteEntry(String entryId);

  /// Analyze journal entry with AI
  Future<Either<Failure, String>> analyzeEntry(String content);
}
