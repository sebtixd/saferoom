import 'package:uuid/uuid.dart';

import '../../../core/constants/app_constants.dart';
import '../../../domain/entities/note_page.dart';
import '../../models/note_page_model.dart';
import 'local_storage_service.dart';

/// Persistent storage for the player's notebook pages.
///
/// Pages are stored per user in SharedPreferences (through the app's existing
/// [LocalStorageService]) so they survive app restarts and are not kept only in
/// memory. A legacy single-note value is migrated into the first page once.
abstract class NotesStorage {
  Future<List<NotePage>> loadPages(String userId);

  Future<void> savePages(String userId, List<NotePage> pages);
}

class SharedPreferencesNotesStorage implements NotesStorage {
  final LocalStorageService _localStorage;

  SharedPreferencesNotesStorage(this._localStorage);

  String _key(String userId) =>
      '${AppConstants.keyNotesPages}_${userId.isEmpty ? 'guest' : userId}';

  @override
  Future<List<NotePage>> loadPages(String userId) async {
    final stored = await _localStorage.getJson(_key(userId));
    final rawPages = stored?['pages'];
    if (rawPages is List) {
      final pages = <NotePage>[];
      for (final entry in rawPages) {
        if (entry is Map<String, dynamic>) {
          pages.add(NotePageModel.fromJson(entry));
        } else if (entry is Map) {
          pages.add(NotePageModel.fromJson(Map<String, dynamic>.from(entry)));
        }
      }
      if (pages.isNotEmpty) return _withPageNumbers(pages);
    }

    // Migrate the old single free-text note into page 1.
    final legacy = await _localStorage.getString('user_notes');
    if (legacy != null && legacy.trim().isNotEmpty) {
      final now = DateTime.now();
      final page = NotePage.create(
        id: const Uuid().v4(),
        content: legacy,
        now: now,
      );
      final pages = [page];
      await savePages(userId, pages);
      await _localStorage.remove('user_notes');
      return pages;
    }

    return const <NotePage>[];
  }

  @override
  Future<void> savePages(String userId, List<NotePage> pages) async {
    final numbered = _withPageNumbers(pages);
    await _localStorage.saveJson(_key(userId), {
      'pages': numbered
          .map((page) => NotePageModel.fromEntity(page).toJson())
          .toList(),
      'updatedAt': DateTime.now().toIso8601String(),
    });
  }

  List<NotePage> _withPageNumbers(List<NotePage> pages) {
    var number = 1;
    return pages
        .map((page) => page.copyWith(pageNumber: number++))
        .toList(growable: false);
  }
}
