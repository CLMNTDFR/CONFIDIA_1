import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api/api_error_message.dart';
import '../../core/auth/auth_provider.dart';
import '../../core/auth/workspace_session.dart';
import '../../shared/data/mock_data.dart';
import '../../shared/models/document_model.dart';
import '../../shared/utils/blob_actions.dart';

class DocumentsState {
  final List<DocumentModel> items;
  final bool loading;
  final String? error;

  const DocumentsState({
    this.items = const [],
    this.loading = false,
    this.error,
  });

  DocumentsState copyWith({
    List<DocumentModel>? items,
    bool? loading,
    String? error,
  }) {
    return DocumentsState(
      items: items ?? this.items,
      loading: loading ?? this.loading,
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

  bool get _demo => _ref.read(authStateProvider).isDemoSession;

  Uint8List? cachedBytes(String id) => _payloads[id];

  void _bind(AuthState auth) {
    _payloads.clear();
    if (!auth.isAuthenticated) {
      state = const DocumentsState();
      return;
    }
    refresh();
  }

  Future<void> refresh() async {
    if (_demo) {
      state = DocumentsState(items: List.of(MockData.documents));
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
      state = DocumentsState(items: list);
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
    if (state.byId(id) == null) return 'Document introuvable';
    if (_demo) {
      _payloads.remove(id);
      state = state.copyWith(items: state.items.where((doc) => doc.id != id).toList());
      return null;
    }
    try {
      final api = _ref.read(apiClientProvider);
      await api.ensureConfigured();
      await api.dio.delete('/documents/$id');
      _payloads.remove(id);
      state = state.copyWith(items: state.items.where((doc) => doc.id != id).toList());
      return null;
    } catch (e) {
      return apiErrorMessage(e, fallback: 'Impossible de supprimer le document');
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
