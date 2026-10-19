import 'package:equatable/equatable.dart';

class DocumentModel extends Equatable {
  final String id;
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
  final DateTime? deletedAt;

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
    this.deletedAt,
  });

  factory DocumentModel.fromJson(Map<String, dynamic> json) {
    return DocumentModel(
      id: json['id'].toString(),
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
      deletedAt: json['deleted_at'] == null ? null : DateTime.parse(json['deleted_at'] as String),
    );
  }

  String get fileSizeFormatted {
    if (fileSize == null) return '';
    if (fileSize! < 1024) return '$fileSize B';
    if (fileSize! < 1048576) return '${(fileSize! / 1024).toStringAsFixed(1)} KB';
    return '${(fileSize! / 1048576).toStringAsFixed(1)} MB';
  }

  bool get isImagePreviewable {
    final mime = mimeType?.toLowerCase() ?? '';
    return mime.startsWith('image/');
  }

  bool get isPdfPreviewable {
    final mime = mimeType?.toLowerCase() ?? '';
    if (mime.contains('pdf')) return true;
    return title.toLowerCase().endsWith('.pdf');
  }

  DocumentModel copyWith({
    String? title,
    DateTime? modified,
    String? correspondent,
    String? documentType,
    List<String>? tags,
    String? category,
    bool? isImportant,
    DateTime? deletedAt,
    bool clearCorrespondent = false,
    bool clearDocumentType = false,
    bool clearCategory = false,
    bool clearDeletedAt = false,
  }) {
    return DocumentModel(
      id: id,
      title: title ?? this.title,
      content: content,
      created: created,
      modified: modified ?? this.modified,
      correspondent: clearCorrespondent ? null : (correspondent ?? this.correspondent),
      documentType: clearDocumentType ? null : (documentType ?? this.documentType),
      tags: tags ?? this.tags,
      category: clearCategory ? null : (category ?? this.category),
      mimeType: mimeType,
      fileSize: fileSize,
      isImportant: isImportant ?? this.isImportant,
      deletedAt: clearDeletedAt ? null : (deletedAt ?? this.deletedAt),
    );
  }

  String get suggestedFilename {
    final base = title.replaceAll(RegExp(r'[/\\]'), '_');
    final ext = switch (mimeType?.toLowerCase()) {
      'application/pdf' => '.pdf',
      'image/png' => '.png',
      'image/jpeg' => '.jpg',
      'image/webp' => '.webp',
      'image/gif' => '.gif',
      _ => '',
    };
    if (ext.isNotEmpty && !base.toLowerCase().endsWith(ext)) return '$base$ext';
    return base;
  }

  @override
  List<Object?> get props => [id, title, category, tags];
}
