import 'package:flutter_test/flutter_test.dart';

import 'package:safe_room/data/datasources/local/notes_storage.dart';
import 'package:safe_room/data/models/note_page_model.dart';
import 'package:safe_room/domain/entities/note_page.dart';

import 'helpers/fakes.dart';

NotePage page(String id, String content, DateTime now, {int number = 1}) =>
    NotePage.create(id: id, content: content, now: now, pageNumber: number);

void main() {
  test('NotePageModel round-trips every persisted field', () {
    final created = DateTime(2026, 11, 22, 10, 30);
    final updated = created.add(const Duration(minutes: 5));
    final page = NotePage(
      id: 'page-1',
      content: 'First line\nSecond line',
      title: 'First line',
      createdAt: created,
      updatedAt: updated,
      pageNumber: 3,
    );

    final json = NotePageModel.fromEntity(page).toJson();
    final restored = NotePageModel.fromJson(json);

    expect(restored.id, page.id);
    expect(restored.content, page.content);
    expect(restored.title, page.title);
    expect(restored.createdAt, created);
    expect(restored.updatedAt, updated);
    expect(restored.pageNumber, 3);
  });

  test('legacy single note is migrated into page 1', () async {
    final localStorage = FakeLocalStorage();
    await localStorage.saveString('user_notes', 'Old single note');
    final storage = SharedPreferencesNotesStorage(localStorage);

    final pages = await storage.loadPages('user-1');

    expect(pages.length, 1);
    expect(pages.first.content, 'Old single note');
    expect(pages.first.pageNumber, 1);
    expect(pages.first.id, isNotEmpty);
    expect(await localStorage.getString('user_notes'), isNull);

    // A fresh storage instance sees the migrated page.
    final reopened = await SharedPreferencesNotesStorage(localStorage)
        .loadPages('user-1');
    expect(reopened.single.id, pages.first.id);
  });

  test('pages survive a restart and can be edited or added separately',
      () async {
    final localStorage = FakeLocalStorage();
    final first = page('page-1', 'First page', DateTime(2026, 11, 22, 9));
    await SharedPreferencesNotesStorage(localStorage)
        .savePages('user-1', [first]);

    // Simulate closing and reopening the app: a brand-new storage instance.
    var storage = SharedPreferencesNotesStorage(localStorage);
    var pages = await storage.loadPages('user-1');
    expect(pages.length, 1);
    expect(pages.first.content, 'First page');
    expect(pages.first.createdAt, first.createdAt);

    // Edit the existing page, keeping its id and creation time.
    final editedTime = DateTime(2026, 11, 22, 10);
    final edited = pages.first.copyWith(
      content: 'First page edited',
      title: NotePage.titleFromContent('First page edited'),
      updatedAt: editedTime,
    );
    final second = page(
      'page-2',
      'A different note',
      DateTime(2026, 11, 22, 11),
      number: 2,
    );
    await storage.savePages('user-1', [edited, second]);

    // Reopen again and verify both pages are still there and editable.
    storage = SharedPreferencesNotesStorage(localStorage);
    pages = await storage.loadPages('user-1');
    expect(pages.length, 2);
    expect(pages[0].id, 'page-1');
    expect(pages[0].content, 'First page edited');
    expect(pages[0].title, 'First page edited');
    expect(pages[0].createdAt, first.createdAt);
    expect(pages[0].updatedAt, editedTime);
    expect(pages[1].id, 'page-2');
    expect(pages[1].content, 'A different note');
    expect(pages.map((p) => p.pageNumber).toList(), [1, 2]);
  });

  test('pages are isolated per user', () async {
    final localStorage = LocalStorageServiceFake();
    await SharedPreferencesNotesStorage(localStorage)
        .savePages('alice', [page('a', 'Alice', DateTime(2026))]);
    await SharedPreferencesNotesStorage(localStorage)
        .savePages('bob', [page('b', 'Bob', DateTime(2026))]);

    final alice = await SharedPreferencesNotesStorage(localStorage)
        .loadPages('alice');
    final bob = await SharedPreferencesNotesStorage(localStorage)
        .loadPages('bob');

    expect(alice.single.content, 'Alice');
    expect(bob.single.content, 'Bob');
  });
}

/// Alias kept explicit so the SharedPreferences contract is obvious in tests.
typedef LocalStorageServiceFake = FakeLocalStorage;
