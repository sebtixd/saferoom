import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';
import 'package:uuid/uuid.dart';

import '../../data/datasources/local/notes_storage.dart';
import '../../domain/entities/note_page.dart';

/// Old Letter style notebook overlay.
///
/// Notes are split into pages. Every save creates a new page or updates the
/// page that is currently open; pages are read from and written to persistent
/// local storage through [NotesStorage].
class NotesOverlay extends StatefulWidget {
  final VoidCallback onClose;
  final String userId;
  final NotesStorage storage;

  const NotesOverlay({
    super.key,
    required this.onClose,
    required this.userId,
    required this.storage,
  });

  @override
  State<NotesOverlay> createState() => _NotesOverlayState();
}

class _NotesOverlayState extends State<NotesOverlay> {
  static const _paper = Color(0xFFFFF8E8);
  static const _ink = Color(0xFF2E1B14);
  static const _mutedInk = Color(0xFF6D5548);
  static const _accent = Color(0xFF8B4513);

  final _controller = TextEditingController();
  final _dateFormat = DateFormat('MMM d, yyyy HH:mm');

  List<NotePage> _pages = <NotePage>[];
  int _currentIndex = 0; // == _pages.length means a brand-new, unsaved page.
  bool _loading = true;
  bool _saving = false;
  bool _dirty = false;

  bool get _isNewPage => _currentIndex >= _pages.length;
  bool get _hasUnsavedContent => _dirty && _controller.text.trim().isNotEmpty;

  @override
  void initState() {
    super.initState();
    _loadPages();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _loadPages() async {
    final pages = await widget.storage.loadPages(widget.userId);
    if (!mounted) return;
    setState(() {
      _pages = pages;
      // Reopen on the most recently written page.
      _currentIndex = pages.isEmpty ? 0 : pages.length - 1;
      _controller.text = pages.isEmpty ? '' : pages.last.content;
      _dirty = false;
      _loading = false;
    });
  }

  Future<void> _saveCurrent({bool showMessage = true}) async {
    if (_saving) return;
    final content = _controller.text;
    setState(() => _saving = true);

    try {
      final now = DateTime.now();
      if (_isNewPage) {
        if (content.trim().isEmpty) {
          if (showMessage) {
            _showMessage('Write something before saving a new page.');
          }
          return;
        }
        final page = NotePage.create(
          id: const Uuid().v4(),
          content: content,
          now: now,
          pageNumber: _pages.length + 1,
        );
        final updated = List<NotePage>.from(_pages)..add(page);
        await widget.storage.savePages(widget.userId, updated);
        if (!mounted) return;
        setState(() {
          _pages = updated;
          _currentIndex = updated.length - 1;
          _dirty = false;
        });
        if (showMessage) _showMessage('Page ${page.pageNumber} saved.');
      } else {
        final current = _pages[_currentIndex];
        final updatedPage = current.copyWith(
          content: content,
          title: NotePage.titleFromContent(content),
          updatedAt: now,
        );
        final updated = List<NotePage>.from(_pages)
          ..[_currentIndex] = updatedPage;
        await widget.storage.savePages(widget.userId, updated);
        if (!mounted) return;
        setState(() {
          _pages = updated;
          _dirty = false;
        });
        if (showMessage) {
          _showMessage('Page ${updatedPage.pageNumber} updated.');
        }
      }
    } catch (error) {
      if (showMessage) _showMessage('Could not save notes: $error');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _openPage(int index) async {
    if (index == _currentIndex) return;
    if (_hasUnsavedContent) await _saveCurrent(showMessage: false);
    if (!mounted) return;
    setState(() {
      _currentIndex = index;
      _controller.text = index < _pages.length ? _pages[index].content : '';
      _dirty = false;
    });
  }

  Future<void> _newPage() async {
    if (_hasUnsavedContent) await _saveCurrent(showMessage: false);
    if (!mounted) return;
    setState(() {
      _currentIndex = _pages.length;
      _controller.clear();
      _dirty = false;
    });
  }

  Future<void> _close() async {
    if (_hasUnsavedContent) await _saveCurrent(showMessage: false);
    if (mounted) widget.onClose();
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), duration: const Duration(seconds: 2)),
    );
  }

  String get _pageLabel {
    final visibleNumber = _isNewPage ? _pages.length + 1 : _currentIndex + 1;
    if (_pages.isEmpty && _isNewPage) return 'New page';
    return 'Page $visibleNumber of ${_pages.length}'
        '${_isNewPage ? ' (new)' : ''}';
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final notesTheme = Theme.of(context).copyWith(
      colorScheme: ColorScheme.fromSeed(
        seedColor: _accent,
        brightness: Theme.of(context).brightness,
      ).copyWith(surface: _paper),
      textSelectionTheme: const TextSelectionThemeData(
        cursorColor: _accent,
        selectionColor: Color(0xFFF0DFC4),
        selectionHandleColor: _accent,
      ),
    );
    return Theme(
      data: notesTheme,
      child: GestureDetector(
        onTap: _close,
        child: Container(
          color: Colors.black.withValues(alpha: 0.7),
          child: Center(
            child: GestureDetector(
              onTap: () {}, // Prevent closing when tapping inside the notebook.
              child: Container(
                width: size.width * 0.9,
                height: size.height * 0.82,
                decoration: BoxDecoration(
                  color: _paper,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFF8D6E63), width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.5),
                      blurRadius: 30,
                      offset: const Offset(0, 15),
                    ),
                  ],
                ),
                child: _loading
                    ? const Center(
                        child: CircularProgressIndicator(color: _accent),
                      )
                    : Padding(
                        padding: const EdgeInsets.fromLTRB(20, 18, 20, 16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _buildHeader(),
                            const SizedBox(height: 14),
                            Expanded(
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  SizedBox(
                                    width: 170,
                                    child: _buildPageList(),
                                  ),
                                  const VerticalDivider(
                                    width: 24,
                                    color: Color(0xFFD7C4AE),
                                  ),
                                  Expanded(child: _buildEditor()),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'My Notes',
                style: TextStyle(
                  fontFamily: 'Serif',
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: _ink,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                _pageLabel,
                style: const TextStyle(fontSize: 13, color: _mutedInk),
              ),
            ],
          ),
        ),
        IconButton(
          tooltip: 'Close notebook',
          icon: const Icon(Icons.close, color: _accent),
          onPressed: _close,
        ),
      ],
    );
  }

  Widget _buildPageList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'PAGES',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
            color: _mutedInk,
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: ListView.builder(
            itemCount: _pages.length + 1,
            itemBuilder: (context, index) {
              final isDraft = index == _pages.length;
              final page = isDraft ? null : _pages[index];
              final selected = index == _currentIndex;
              final subtitle = isDraft
                  ? 'Unsaved draft'
                  : '${page!.title}  ·  ${_dateFormat.format(page.updatedAt)}';
              return Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Material(
                  color: Colors.transparent,
                  child: ListTile(
                    dense: true,
                    selected: selected,
                    selectedTileColor: const Color(0xFFF0DFC4),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                      side: BorderSide(
                        color: selected ? _accent : const Color(0xFFD7C4AE),
                      ),
                    ),
                    title: Text(
                      isDraft ? 'Page ${_pages.length + 1}' : 'Page ${index + 1}',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: _ink,
                      ),
                    ),
                    subtitle: Text(
                      subtitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 11, color: _mutedInk),
                    ),
                    onTap: () => _openPage(index),
                  ),
                ),
              );
            },
          ),
        ),
        OutlinedButton.icon(
          onPressed: _newPage,
          icon: const Icon(Icons.add, size: 18),
          label: const Text('New Page'),
          style: OutlinedButton.styleFrom(
            foregroundColor: _accent,
            side: const BorderSide(color: _accent),
          ),
        ),
      ],
    );
  }

  Widget _buildEditor() {
    final current = _isNewPage ? null : _pages[_currentIndex];
    final created =
        current == null ? 'Not saved yet' : 'Created ${_dateFormat.format(current.createdAt)}';
    final updated =
        current == null ? '' : 'Updated ${_dateFormat.format(current.updatedAt)}';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                created,
                style: const TextStyle(fontSize: 12, color: _mutedInk),
              ),
            ),
            if (updated.isNotEmpty)
              Text(
                updated,
                style: const TextStyle(fontSize: 12, color: _mutedInk),
              ),
          ],
        ),
        const SizedBox(height: 8),
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.72),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFD7C4AE)),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              child: TextField(
                controller: _controller,
                maxLines: null,
                expands: true,
                textAlignVertical: TextAlignVertical.top,
                onChanged: (_) => setState(() => _dirty = true),
                decoration: const InputDecoration(
                  hintText: 'Write your thoughts on this page...',
                  hintStyle: TextStyle(
                    color: _mutedInk,
                    fontStyle: FontStyle.italic,
                  ),
                  border: InputBorder.none,
                ),
                style: const TextStyle(
                  fontFamily: 'Serif',
                  fontSize: 18,
                  height: 1.7,
                  color: _ink,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            IconButton(
              tooltip: 'Previous page',
              icon: const Icon(Icons.chevron_left),
              color: _accent,
              onPressed: _currentIndex > 0
                  ? () => _openPage(_currentIndex - 1)
                  : null,
            ),
            IconButton(
              tooltip: 'Next page',
              icon: const Icon(Icons.chevron_right),
              color: _accent,
              onPressed: !_isNewPage
                  ? () => _openPage(_currentIndex + 1)
                  : null,
            ),
            const Spacer(),
            ElevatedButton.icon(
              onPressed: _saving ? null : () => _saveCurrent(),
              icon: _saving
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.save, color: Colors.white),
              label: Text(
                _saving
                    ? 'Saving...'
                    : (_isNewPage ? 'Save New Page' : 'Save Changes'),
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: _accent,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 22,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
