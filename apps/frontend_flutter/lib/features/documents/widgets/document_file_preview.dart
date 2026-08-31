import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:pdfrx/pdfrx.dart';

import '../../../core/theme/colors.dart';
import '../../../core/theme/spacing.dart';
import '../../../shared/models/document_model.dart';

/// Aperçu visuel du fichier (image ou PDF) dans l'encart de détail.
class DocumentFilePreview extends StatelessWidget {
  final DocumentModel doc;
  final Uint8List? bytes;
  final bool loading;
  final VoidCallback onDownload;

  const DocumentFilePreview({
    super.key,
    required this.doc,
    required this.bytes,
    required this.loading,
    required this.onDownload,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Aperçu', style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        Container(
          height: 480,
          width: double.infinity,
          decoration: BoxDecoration(
            color: isDark ? ConfidiaColors.darkSurfaceVariant : ConfidiaColors.lightSurfaceElevated,
            borderRadius: BorderRadius.circular(ConfidiaSpacing.radiusMd),
            border: Border.all(color: ConfidiaColors.border(isDark)),
          ),
          clipBehavior: Clip.antiAlias,
          child: _body(context, isDark),
        ),
      ],
    );
  }

  Widget _body(BuildContext context, bool isDark) {
    if (loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (bytes != null && doc.isImagePreviewable) {
      return InteractiveViewer(
        child: Image.memory(bytes!, fit: BoxFit.contain),
      );
    }
    if (bytes != null && doc.isPdfPreviewable) {
      return PdfViewer.data(
        bytes!,
        sourceName: 'confidia-doc-${doc.id}',
        params: PdfViewerParams(
          margin: 8,
          backgroundColor: isDark ? ConfidiaColors.darkSurfaceVariant : ConfidiaColors.lightSurfaceElevated,
          loadingBannerBuilder: (context, bytesDownloaded, totalBytes) =>
              const Center(child: CircularProgressIndicator()),
          errorBannerBuilder: (context, error, stackTrace, documentRef) =>
              _Unavailable(
                context: context,
                isDark: isDark,
                title: doc.title,
                message: 'Impossible d\'afficher ce PDF. Vous pouvez le télécharger.',
                onDownload: onDownload,
              ),
        ),
      );
    }
    return _Unavailable(
      context: context,
      isDark: isDark,
      title: bytes == null ? 'Aperçu indisponible' : doc.title,
      message: bytes == null
          ? 'Le fichier n\'a pas pu être chargé. Réessayez le téléchargement.'
          : 'Aperçu visuel limité pour ce type de fichier.',
      onDownload: onDownload,
    );
  }
}

class _Unavailable extends StatelessWidget {
  final BuildContext context;
  final bool isDark;
  final String title;
  final String message;
  final VoidCallback onDownload;

  const _Unavailable({
    required this.context,
    required this.isDark,
    required this.title,
    required this.message,
    required this.onDownload,
  });

  @override
  Widget build(BuildContext _) {
    final muted = ConfidiaColors.textSecondary(isDark);
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.insert_drive_file_outlined, size: 52, color: muted.withValues(alpha: 0.55)),
          const SizedBox(height: 12),
          Text(title, textAlign: TextAlign.center, style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: 4),
          Text(
            message,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(color: muted),
          ),
          const SizedBox(height: 16),
          TextButton.icon(
            onPressed: onDownload,
            icon: const Icon(Icons.download_outlined, size: 16),
            label: const Text('Télécharger'),
          ),
        ],
      ),
    );
  }
}
