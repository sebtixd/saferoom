import 'package:equatable/equatable.dart';

/// Journal events
abstract class JournalEvent extends Equatable {
  const JournalEvent();

  @override
  List<Object?> get props => [];
}

/// Load journal entries
class JournalLoadEntries extends JournalEvent {
  final String userId;
  const JournalLoadEntries(this.userId);

  @override
  List<Object?> get props => [userId];
}

/// Save journal entry
class JournalSaveEntry extends JournalEvent {
  final String userId;
  final String content;
  final String? mood;

  const JournalSaveEntry({
    required this.userId,
    required this.content,
    this.mood,
  });

  @override
  List<Object?> get props => [userId, content, mood];
}

/// Delete journal entry
class JournalDeleteEntry extends JournalEvent {
  final String entryId;
  const JournalDeleteEntry(this.entryId);

  @override
  List<Object?> get props => [entryId];
}
