import 'package:dartz/dartz.dart';
import '../../../core/errors/failures.dart';
import '../../entities/journal_entry.dart';
import '../../repositories/journal_repository.dart';

/// Use case for getting journal entries
class GetJournalEntriesUseCase {
  final JournalRepository repository;

  GetJournalEntriesUseCase(this.repository);

  Future<Either<Failure, List<JournalEntry>>> call(String userId) {
    return repository.getEntries(userId);
  }
}
