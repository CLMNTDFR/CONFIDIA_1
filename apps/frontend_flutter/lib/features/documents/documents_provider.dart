import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api/api_error_message.dart';
import '../../core/auth/auth_provider.dart';
import '../../core/auth/workspace_session.dart';
import '../../shared/data/mock_data.dart';
import '../../shared/models/document_model.dart';
import '../../shared/utils/blob_actions.dart';
import '../calendar/calendar_provider.dart';

class DocumentEventLink {
  final String eventId;
  final String title;
  final DateTime start;
  final bool deleted;

  const DocumentEventLink({
    required this.eventId,
    required this.title,
    required this.start,
    required this.deleted,
  });

  factory DocumentEventLink.fromJson(Map<String, dynamic> json) {
    return DocumentEventLink(
      eventId: json['event_id'].toString(),
      title: json['title'] as String? ?? 'Événement',
      start: DateTime.parse(json['start'] as String),
      deleted: json['deleted'] as bool? ?? false,
    );
  }
}

class DocumentPurgeDecision {
  final String eventId;
  final String action;

  const DocumentPurgeDecision({required this.eventId, required this.action});

  Map<String, String> toJson() => {'event_id': eventId, 'action': action};
}

class DocumentsState {
  final List<DocumentModel> items;
  final List<DocumentModel> trash;
  final bool loading;
  final bool trashLoading;
  final String? error;

  const DocumentsState({
    this.items = const [],
    this.trash = const [],
    this.loading = false,
    this.trashLoading = false,
    this.error,
  });

  DocumentsState copyWith({
    List<DocumentModel>? items,
    List<DocumentModel>? trash,
    bool? loading,
    bool? trashLoading,
    String? error,
  }) {
    return DocumentsState(
      items: items ?? this.items,
      trash: trash ?? this.trash,
      loading: loading ?? this.loading,
      trashLoading: trashLoading ?? this.trashLoading,
      error: error,
    );
  }

  DocumentModel? byId(String id) {
    for (final doc in items) {
      if (doc.id == id) return doc;
    }
    return null;
  }
}

class DocumentsNotifier extends StateNotifier<DocumentsState> {
  DocumentsNotifier(this._ref) : super(const DocumentsState()) {
    _bind(_ref.read(authStateProvider));
    _ref.listen<AuthState>(authStateProvider, (prev, next) {
      if (!workspaceSessionChanged(prev, next)) return;
      _bind(next);
    });
  }

  final Ref _ref;
  final Map<String, Uint8List> _payloads = {};
  final Map<String, DocumentModel> _demoTrash = {};
  final Set<String> _demoPurged = {};

  bool get _demo => _ref.read(authStateProvider).isDemoSession;

  Uint8List? cachedBytes(String id) => _payloads[id];

  void _bind(AuthState auth) {
    _payloads.clear();
    _demoTrash.clear();
    _demoPurged.clear();
    if (!auth.isAuthenticated) {
      state = const DocumentsState();
      return;
    }
    refresh();
  }

  void _publishDemo() {
    final hidden = {..._demoPurged, ..._demoTrash.keys};
    final mockIds = MockData.documents.map((doc) => doc.id).toSet();
    final uploaded = [
      for (final doc in state.items)
        if (!mockIds.contains(doc.id) && !hidden.contains(doc.id)) doc,
    ];
    state = DocumentsState(
      items: [
        for (final doc in MockData.documents)
          if (!hidden.contains(doc.id)) doc,
        ...uploaded,
      ],
      trash: _demoTrash.values.toList(),
    );
  }

  Future<void> refresh() async {
    if (_demo) {
      _publishDemo();
      return;
    }
    if (!_ref.read(authStateProvider).isAuthenticated) {
      state = const DocumentsState();
      return;
    }
    state = state.copyWith(loading: true, error: null);
    try {
      final api = _ref.read(apiClientProvider);
      await api.ensureConfigured();
      final response = await api.dio.get('/documents/');
      final list = (response.data['items'] as List<dynamic>)
          .map((e) => DocumentModel.fromJson(e as Map<String, dynamic>))
          .toList();
      final keep = {for (final doc in list) doc.id};
      _payloads.removeWhere((id, _) => !keep.contains(id));
      state = DocumentsState(items: list, trash: state.trash);
    } catch (e) {
      state = state.copyWith(
        loading: false,
        error: apiErrorMessage(e, fallback: 'Impossible de charger les documents'),
      );
    }
  }

  Future<DocumentModel?> upload({
    required String filename,
    required Uint8List bytes,
    String? title,
    String? category,
    String? documentType,
  }) async {
    if (_demo) {
      final doc = DocumentModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        title: title ?? filename,
        created: DateTime.now(),
        modified: DateTime.now(),
        category: category,
        documentType: documentType?.trim().isEmpty == true ? null : documentType?.trim(),
        mimeType: _mimeFromFilename(filename),
        fileSize: bytes.length,
      );
      _payloads[doc.id] = bytes;
      state = state.copyWith(items: [doc, ...state.items]);
      return doc;
    }
    try {
      final api = _ref.read(apiClientProvider);
      await api.ensureConfigured();
      final form = FormData.fromMap({
        'file': MultipartFile.fromBytes(bytes, filename: filename),
        if (title != null && title.isNotEmpty) 'title': title,
        if (category != null && category.isNotEmpty) 'category': category,
        if (documentType != null && documentType.trim().isNotEmpty) 'document_type': documentType.trim(),
      });
      final response = await api.dio.post('/documents/upload', data: form);
      final doc = DocumentModel.fromJson(response.data as Map<String, dynamic>);
      _payloads[doc.id] = bytes;
      state = state.copyWith(items: [doc, ...state.items]);
      return doc;
    } catch (e) {
      state = state.copyWith(
        error: apiErrorMessage(e, fallback: "Échec de l'envoi du document"),
      );
      return null;
    }
  }

  Future<Uint8List?> loadBytes(String id) async {
    final cached = _payloads[id];
    if (cached != null) return cached;
    if (_demo) return null;
    try {
      final api = _ref.read(apiClientProvider);
      await api.ensureConfigured();
      final response = await api.dio.get<List<int>>(
        '/documents/$id/file',
        options: Options(responseType: ResponseType.bytes),
      );
      final data = response.data;
      if (data == null) return null;
      final bytes = Uint8List.fromList(data);
      _payloads[id] = bytes;
      return bytes;
    } catch (_) {
      return null;
    }
  }

  Future<String?> download(String id) async {
    final doc = state.byId(id);
    final bytes = await loadBytes(id);
    if (doc == null) return 'Document introuvable';
    if (bytes == null) {
      return _demo
          ? 'Aperçu fichier indisponible en mode démo pour ce document.'
          : 'Impossible de télécharger le fichier.';
    }
    downloadBytes(bytes, doc.suggestedFilename, doc.mimeType ?? 'application/octet-stream');
    if (!blobActionsSupported) {
      return 'Téléchargement disponible dans le navigateur.';
    }
    return null;
  }

  Future<String?> updateDocument({
    required String id,
    String? title,
    String? category,
    String? correspondent,
    String? documentType,
  }) async {
    final current = state.byId(id);
    if (current == null) return 'Document introuvable';
    final nextTitle = title?.trim();
    if (nextTitle != null && nextTitle.isEmpty) return 'Le titre est requis';

    if (_demo) {
      final next = current.copyWith(
        title: nextTitle,
        category: category,
        correspondent: correspondent,
        documentType: documentType,
        clearCategory: category != null && category.trim().isEmpty,
        clearCorrespondent: correspondent != null && correspondent.trim().isEmpty,
        clearDocumentType: documentType != null && documentType.trim().isEmpty,
        modified: DateTime.now(),
      );
      state = state.copyWith(
        items: [for (final doc in state.items) if (doc.id == id) next else doc],
      );
      return null;
    }
    try {
      final api = _ref.read(apiClientProvider);
      await api.ensureConfigured();
      final response = await api.dio.patch(
        '/documents/$id',
        data: {
          if (nextTitle != null) 'title': nextTitle,
          if (category != null) 'category': category.trim().isEmpty ? null : category.trim(),
          if (correspondent != null)
            'correspondent': correspondent.trim().isEmpty ? null : correspondent.trim(),
          if (documentType != null)
            'document_type': documentType.trim().isEmpty ? null : documentType.trim(),
        },
      );
      final doc = DocumentModel.fromJson(response.data as Map<String, dynamic>);
      final bytes = _payloads[id];
      state = state.copyWith(
        items: [for (final item in state.items) if (item.id == id) doc else item],
      );
      if (bytes != null) _payloads[doc.id] = bytes;
      return null;
    } catch (e) {
      return apiErrorMessage(e, fallback: 'Impossible d\'enregistrer le document');
    }
  }

  Future<String?> deleteDocument(String id) async {
    final current = state.byId(id);
    if (current == null) return 'Document introuvable';
    if (_demo) {
      final trashed = current.copyWith(deletedAt: DateTime.now());
      _demoTrash[id] = trashed;
      state = state.copyWith(
        items: state.items.where((doc) => doc.id != id).toList(),
        trash: [trashed, ...state.trash.where((doc) => doc.id != id)],
      );
      return null;
    }
    try {
      final api = _ref.read(apiClientProvider);
      await api.ensureConfigured();
      await api.dio.delete('/documents/$id');
      _payloads.remove(id);
      state = state.copyWith(
        items: state.items.where((doc) => doc.id != id).toList(),
        trash: [current.copyWith(deletedAt: DateTime.now()), ...state.trash.where((doc) => doc.id != id)],
      );
      return null;
    } catch (e) {
      return apiErrorMessage(e, fallback: 'Impossible de supprimer le document');
    }
  }

  Future<void> refreshTrash() async {
    if (_demo) return;
    if (!_ref.read(authStateProvider).isAuthenticated) {
      state = const DocumentsState();
      return;
    }
    state = state.copyWith(trashLoading: true, error: null);
    try {
      final api = _ref.read(apiClientProvider);
      await api.ensureConfigured();
      final response = await api.dio.get('/documents/trash', queryParameters: {'page_size': 100});
      final list = (response.data['items'] as List<dynamic>)
          .map((item) => DocumentModel.fromJson(item as Map<String, dynamic>))
          .toList();
      state = state.copyWith(trash: list, trashLoading: false, error: null);
    } catch (e) {
      state = state.copyWith(
        trashLoading: false,
        error: apiErrorMessage(e, fallback: 'Impossible de charger la corbeille'),
      );
    }
  }

  Future<String?> restoreDocument(String id) async {
    if (_demo) {
      final doc = _demoTrash.remove(id);
      if (doc == null) return 'Document introuvable';
      state = state.copyWith(
        trash: state.trash.where((item) => item.id != id).toList(),
        items: [...state.items.where((item) => item.id != id), doc.copyWith(clearDeletedAt: true)],
      );
      return null;
    }
    try {
      final api = _ref.read(apiClientProvider);
      await api.ensureConfigured();
      final response = await api.dio.post('/documents/$id/restore');
      final doc = DocumentModel.fromJson(response.data as Map<String, dynamic>);
      state = state.copyWith(
        trash: state.trash.where((item) => item.id != id).toList(),
        items: [doc, ...state.items.where((item) => item.id != id)],
      );
      return null;
    } catch (e) {
      return apiErrorMessage(e, fallback: 'Impossible de restaurer le document');
    }
  }

  Future<({List<DocumentEventLink>? links, String? error})> eventLinks(String id) async {
    if (_demo) {
      final numeric = int.tryParse(id);
      if (numeric == null) return (links: const <DocumentEventLink>[], error: null);
      return (
        links: [
          for (final event in _ref.read(calendarProvider).items)
            if (event.documentId == numeric)
              DocumentEventLink(
                eventId: event.id,
                title: event.title,
                start: event.start,
                deleted: false,
              ),
        ],
        error: null,
      );
    }
    try {
      final api = _ref.read(apiClientProvider);
      await api.ensureConfigured();
      final response = await api.dio.get('/documents/$id/links');
      final links = (response.data as List<dynamic>)
          .map((item) => DocumentEventLink.fromJson(item as Map<String, dynamic>))
          .toList();
      return (links: links, error: null);
    } catch (e) {
      return (links: null, error: apiErrorMessage(e, fallback: 'Impossible de lire les liens'));
    }
  }

  Future<String?> purgeDocument(String id, List<DocumentPurgeDecision> decisions) async {
    if (_demo) {
      if (_demoTrash.remove(id) == null) return 'Document introuvable';
      _demoPurged.add(id);
      _payloads.remove(id);
      final calendar = _ref.read(calendarProvider.notifier);
      for (final decision in decisions) {
        if (decision.action == 'delete') {
          await calendar.delete(decision.eventId);
        } else {
          calendar.clearDocumentLink(decision.eventId);
        }
      }
      state = state.copyWith(trash: state.trash.where((doc) => doc.id != id).toList());
      return null;
    }
    try {
      final api = _ref.read(apiClientProvider);
      await api.ensureConfigured();
      await api.dio.post(
        '/documents/$id/purge',
        data: {'decisions': decisions.map((decision) => decision.toJson()).toList()},
      );
      _payloads.remove(id);
      state = state.copyWith(trash: state.trash.where((doc) => doc.id != id).toList());
      if (decisions.isNotEmpty) {
        await _ref.read(calendarProvider.notifier).refresh();
      }
      return null;
    } catch (e) {
      return apiErrorMessage(e, fallback: 'Impossible de supprimer définitivement le document');
    }
  }

  static String? _mimeFromFilename(String filename) {
    final lower = filename.toLowerCase();
    if (lower.endsWith('.pdf')) return 'application/pdf';
    if (lower.endsWith('.png')) return 'image/png';
    if (lower.endsWith('.jpg') || lower.endsWith('.jpeg')) return 'image/jpeg';
    if (lower.endsWith('.webp')) return 'image/webp';
    if (lower.endsWith('.gif')) return 'image/gif';
    return null;
  }
}

final documentsProvider = StateNotifierProvider<DocumentsNotifier, DocumentsState>((ref) {
  return DocumentsNotifier(ref);
});
