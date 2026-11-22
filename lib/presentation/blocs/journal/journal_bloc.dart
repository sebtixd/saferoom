import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../domain/entities/journal_entry.dart';
import '../../../domain/usecases/journal/save_journal_entry_usecase.dart';
import '../../../domain/usecases/journal/get_journal_entries_usecase.dart';
import 'journal_event.dart';
import 'journal_state.dart';

/// Journal BLoC
class JournalBloc extends Bloc<JournalEvent, JournalState> {
  final SaveJournalEntryUseCase saveJournalEntryUseCase;
  final GetJournalEntriesUseCase getJournalEntriesUseCase;

  JournalBloc({
    required this.saveJournalEntryUseCase,
    required this.getJournalEntriesUseCase,
  }) : super(const JournalInitial()) {
    on<JournalLoadEntries>(_onLoadEntries);
    on<JournalSaveEntry>(_onSaveEntry);
  }

  Future<void> _onLoadEntries(
    JournalLoadEntries event,
    Emitter<JournalState> emit,
  ) async {
    emit(const JournalLoading());

    final result = await getJournalEntriesUseCase(event.userId);

    result.fold(
      (failure) => emit(JournalError(failure.message)),
      (entries) => emit(JournalLoaded(entries: entries)),
    );
  }

  Future<void> _onSaveEntry(
    JournalSaveEntry event,
    Emitter<JournalState> emit,
  ) async {
    final currentState = state;
    final currentEntries = currentState is JournalLoaded ? currentState.entries : <JournalEntry>[];

    emit(JournalLoaded(entries: currentEntries, isSaving: true));

    final entry = _JournalEntryData(
      id: '',
      userId: event.userId,
      content: event.content,
      timestamp: DateTime.now(),
      mood: event.mood,
    );

    final result = await saveJournalEntryUseCase(entry);

    result.fold(
      (failure) => emit(JournalError(failure.message)),
      (savedEntry) => emit(JournalLoaded(
        entries: [savedEntry, ...currentEntries],
        isSaving: false,
      )),
    );
  }
}

// Internal class for creating entry
class _JournalEntryData extends JournalEntry {
  const _JournalEntryData({
    required super.id,
    required super.userId,
    required super.content,
    required super.timestamp,
    super.mood,
  });
}
