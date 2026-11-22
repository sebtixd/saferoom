import 'package:dartz/dartz.dart';
import '../../../core/errors/failures.dart';
import '../../entities/journal_entry.dart';
import '../../repositories/journal_repository.dart';

/// Use case for saving journal entry
class SaveJournalEntryUseCase {
  final JournalRepository repository;

  SaveJournalEntryUseCase(this.repository);

  Future<Either<Failure, JournalEntry>> call(JournalEntry entry) {
    return repository.saveEntry(entry);
  }
}
