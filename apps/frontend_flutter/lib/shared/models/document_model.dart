import 'package:equatable/equatable.dart';

class DocumentModel extends Equatable {
  final int id;
  final String title;
  final String? content;
  final DateTime created;
  final DateTime modified;
  final String? correspondent;
  final String? documentType;
  final List<String> tags;
  final String? category;
  final String? mimeType;
  final int? fileSize;
  final bool isImportant;

  const DocumentModel({
    required this.id,
    required this.title,
    this.content,
    required this.created,
    required this.modified,
    this.correspondent,
    this.documentType,
    this.tags = const [],
    this.category,
    this.mimeType,
    this.fileSize,
    this.isImportant = false,
  });

  factory DocumentModel.fromJson(Map<String, dynamic> json) {
    return DocumentModel(
      id: json['id'] as int,
      title: json['title'] as String,
      content: json['content'] as String?,
      created: DateTime.parse(json['created'] as String),
      modified: DateTime.parse(json['modified'] as String),
      correspondent: json['correspondent'] as String?,
      documentType: json['document_type'] as String?,
      tags: List<String>.from(json['tags'] ?? []),
      category: json['category'] as String?,
      mimeType: json['mime_type'] as String?,
      fileSize: json['file_size'] as int?,
      isImportant: json['is_important'] as bool? ?? false,
    );
  }

  String get fileSizeFormatted {
    if (fileSize == null) return '';
    if (fileSize! < 1024) return '$fileSize B';
    if (fileSize! < 1048576) return '${(fileSize! / 1024).toStringAsFixed(1)} KB';
    return '${(fileSize! / 1048576).toStringAsFixed(1)} MB';
  }

  @override
  List<Object?> get props => [id, title, category, tags];
}
