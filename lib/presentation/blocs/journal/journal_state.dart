import 'package:equatable/equatable.dart';
import '../../../domain/entities/journal_entry.dart';

/// Journal states
abstract class JournalState extends Equatable {
  const JournalState();

  @override
  List<Object?> get props => [];
}

class JournalInitial extends JournalState {
  const JournalInitial();
}

class JournalLoading extends JournalState {
  const JournalLoading();
}

class JournalLoaded extends JournalState {
  final List<JournalEntry> entries;
  final bool isSaving;

  const JournalLoaded({
    required this.entries,
    this.isSaving = false,
  });

  @override
  List<Object?> get props => [entries, isSaving];
}

class JournalError extends JournalState {
  final String message;

  const JournalError(this.message);

  @override
  List<Object?> get props => [message];
}
