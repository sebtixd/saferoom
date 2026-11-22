import 'package:equatable/equatable.dart';

/// A single page in the player's notebook.
///
/// Pages are stored as a list per user. [pageNumber] is a 1-based display
/// index derived from the page's position; [title] is generated from the first
/// line of [content] so the page navigator has something readable to show.
class NotePage extends Equatable {
  final String id;
  final String content;
  final String title;
  final DateTime createdAt;
  final DateTime updatedAt;
  final int pageNumber;

  const NotePage({
    required this.id,
    required this.content,
    required this.title,
    required this.createdAt,
    required this.updatedAt,
    this.pageNumber = 1,
  });

  /// Builds a page, deriving a short title from its content.
  factory NotePage.create({
    required String id,
    required String content,
    required DateTime now,
    int pageNumber = 1,
  }) {
    return NotePage(
      id: id,
      content: content,
      title: titleFromContent(content),
      createdAt: now,
      updatedAt: now,
      pageNumber: pageNumber,
    );
  }

  bool get isEmpty => content.trim().isEmpty;

  NotePage copyWith({
    String? id,
    String? content,
    String? title,
    DateTime? createdAt,
    DateTime? updatedAt,
    int? pageNumber,
  }) {
    return NotePage(
      id: id ?? this.id,
      content: content ?? this.content,
      title: title ?? this.title,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      pageNumber: pageNumber ?? this.pageNumber,
    );
  }

  static String titleFromContent(String content) {
    final firstLine = content.trim().split(RegExp(r'\r?\n')).first.trim();
    const fallback = 'Untitled page';
    if (firstLine.isEmpty) return fallback;
    const maxLength = 34;
    if (firstLine.length <= maxLength) return firstLine;
    return '${firstLine.substring(0, maxLength).trimRight()}…';
  }

  @override
  List<Object?> get props => [
        id,
        content,
        title,
        createdAt,
        updatedAt,
        pageNumber,
      ];
}
