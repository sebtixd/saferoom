import '../../domain/entities/note_page.dart';

/// JSON adapter for persisting [NotePage] objects in local storage.
class NotePageModel extends NotePage {
  const NotePageModel({
    required super.id,
    required super.content,
    required super.title,
    required super.createdAt,
    required super.updatedAt,
    super.pageNumber,
  });

  factory NotePageModel.fromEntity(NotePage page) {
    return NotePageModel(
      id: page.id,
      content: page.content,
      title: page.title,
      createdAt: page.createdAt,
      updatedAt: page.updatedAt,
      pageNumber: page.pageNumber,
    );
  }

  factory NotePageModel.fromJson(Map<String, dynamic> json) {
    final content = json['content'] as String? ?? '';
    return NotePageModel(
      id: json['id'] as String,
      content: content,
      title: json['title'] as String? ?? NotePage.titleFromContent(content),
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(
        (json['updatedAt'] as String?) ?? (json['createdAt'] as String),
      ),
      pageNumber: json['pageNumber'] as int? ?? 1,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'content': content,
      'title': title,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'pageNumber': pageNumber,
    };
  }
}
