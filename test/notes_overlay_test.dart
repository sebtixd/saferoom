import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'package:safe_room/data/datasources/local/notes_storage.dart';
import 'package:safe_room/presentation/widgets/notes_overlay.dart';

import 'helpers/fakes.dart';

Widget _host({
  required NotesStorage storage,
  required VoidCallback onClose,
}) {
  return MaterialApp(
    home: Scaffold(
      body: NotesOverlay(
        userId: 'user-1',
        storage: storage,
        onClose: onClose,
      ),
    ),
  );
}

String _editorText(WidgetTester tester) =>
    tester.widget<TextField>(find.byType(TextField)).controller!.text;

void main() {
  testWidgets('notes are saved as pages, reopened, edited and added to',
      (tester) async {
    final storage = SharedPreferencesNotesStorage(FakeLocalStorage());
    var closed = false;

    await tester.pumpWidget(_host(
      storage: storage,
      onClose: () => closed = true,
    ));
    await tester.pumpAndSettle();

    expect(find.text('New page'), findsOneWidget);
    await tester.enterText(find.byType(TextField), 'First thought');
    await tester.tap(find.text('Save New Page'));
    await tester.pumpAndSettle();

    expect(find.text('Page 1 of 1'), findsOneWidget);
    final firstId = (await storage.loadPages('user-1')).single.id;
    expect((await storage.loadPages('user-1')).single.content, 'First thought');

    // Simulate closing the app and reopening it with the same storage.
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();
    await tester.pumpWidget(_host(
      storage: storage,
      onClose: () => closed = true,
    ));
    await tester.pumpAndSettle();

    expect(find.text('Page 1 of 1'), findsOneWidget);
    expect(_editorText(tester), 'First thought');

    // Editing an old page updates that same page.
    await tester.enterText(find.byType(TextField), 'First thought edited');
    await tester.tap(find.text('Save Changes'));
    await tester.pumpAndSettle();

    var pages = await storage.loadPages('user-1');
    expect(pages.length, 1);
    expect(pages.single.id, firstId);

    // A new page is stored separately.
    await tester.tap(find.text('New Page'));
    await tester.pumpAndSettle();
    expect(find.text('Page 2 of 1 (new)'), findsOneWidget);
    await tester.enterText(find.byType(TextField), 'Second thought');
    await tester.tap(find.text('Save New Page'));
    await tester.pumpAndSettle();

    pages = await storage.loadPages('user-1');
    expect(pages.length, 2);
    expect(pages[0].content, 'First thought edited');
    expect(pages[1].content, 'Second thought');
    expect(find.text('Page 2 of 2'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.close));
    await tester.pumpAndSettle();
    expect(closed, true);
  });
}
